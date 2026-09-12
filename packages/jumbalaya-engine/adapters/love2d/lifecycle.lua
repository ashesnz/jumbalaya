--[[ jumbalaya-engine/adapters/love2d/lifecycle.lua - LÖVE lifecycle callbacks and custom frame loop ]]

local shell = require("jumbalaya-engine.shell")
local Window = require("jumbalaya-engine.adapters.love2d.window")

function love.run()
	love.load(love.arg.parseGameArguments(arg), arg)
	love.timer.step()

	local dt = 0.0
	local dt_smooth = 1 / 100
	local run_time = 0.0

	return function()
		run_time = love.timer.getTime()

		local game = shell.game()
		if game and game.INPUT then
			love.event.pump()
			local event_name, a, b, c, d, e, f, touched
			for name, event_a, event_b, event_c, event_d, event_e, event_f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return event_a or 0
					end
				elseif name == "touchpressed" then
					touched = true
				elseif name == "mousepressed" then
					event_name, a, b, c, d, e, f =
						name, event_a, event_b, event_c, event_d, event_e, event_f
				else
					love.handlers[name](event_a, event_b, event_c, event_d, event_e, event_f)
				end
			end
			if event_name then
				love.handlers.mousepressed(a, b, c, touched)
			end
		end

		dt = love.timer.step()
		dt_smooth = math.min(0.8 * dt_smooth + 0.2 * dt, 0.1)
		love.update(dt_smooth)

		if love.graphics.isActive() then
			love.draw()
			love.graphics.present()
		end

		run_time = math.min(love.timer.getTime() - run_time, 0.1)
		game = shell.game()
		game.FPS_CAP = game.FPS_CAP or 500
		if run_time < 1 / game.FPS_CAP then
			love.timer.sleep(1 / game.FPS_CAP - run_time)
		end
	end
end

function love.load()
	love.window.setTitle("Jumbalaya")

	local os_name = love.system.getOS()
	if os_name == "iOS" or os_name == "Android" then
		Window.lock_landscape_orientation()
		Window.apply_mobile_window()
	end

	local game = shell.game()
	game:launch()
	Dictionary.load()

	if os_name == "iOS" or os_name == "Android" then
		Window.sync_resize()
	end

	if os_name == "OS X" or os_name == "Windows" then
		local steam
		local ok, result = pcall(function()
			if os_name == "OS X" then
				local source_dir = love.filesystem.getSourceBaseDirectory()
				local old_cpath = package.cpath
				package.cpath = package.cpath .. ";" .. source_dir .. "/?.so"
				steam = require "luasteam"
				package.cpath = old_cpath
			else
				steam = require "luasteam"
			end
			return steam
		end)

		if ok and result and result.init and result:init() then
			result.send_control = {
				last_sent_time = -200,
				last_sent_stage = -1,
				force = false,
			}
			game.STEAM = result
		else
			print("Steam not available — running without Steam integration")
			game.STEAM = nil
		end
	end

	love.mouse.setVisible(false)
end

function love.quit()
	local game = shell.game()
	if not game then return end
	if game.AUDIO_WORKER then
		game.AUDIO_WORKER.channel:push({ op = "stop" })
	end
	if game.STEAM then
		game.STEAM:shutdown()
	end
end

function love.update(dt)
	perf_checkpoint(nil, "update", true)
	shell.game():update(dt)
end

function love.draw()
	perf_checkpoint(nil, "draw", true)
	shell.game():draw()
end

return true
