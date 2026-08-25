-- LÖVE lifecycle callbacks and the custom frame loop.

--- Custom replacement for LÖVE's default `love.run`.
--- Adds an FPS cap and coalesces mouse-press events so only the last press in
--- each frame is dispatched.
---@return function frame_fn
function love.run()
	love.load(love.arg.parseGameArguments(arg), arg)
	love.timer.step()

	local dt = 0.0
	local dt_smooth = 1 / 100
	---@type number
	local run_time = 0.0

	return function()
		run_time = love.timer.getTime()

		if G and G.INPUT then
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
		G.FPS_CAP = G.FPS_CAP or 500
		if run_time < 1 / G.FPS_CAP then
			love.timer.sleep(1 / G.FPS_CAP - run_time)
		end
	end
end

--- Boots the game and optional Steam integration.
function love.load()
	love.window.setTitle("Jumbalaya")

	-- Lock landscape before boot on mobile. iOS ignores landscape hints if this
	-- runs too late or uses fullscreentype='desktop' (see app/window.lua).
	local os_name = love.system.getOS()
	if os_name == "iOS" or os_name == "Android" then
		require("app.core.platform.window").lock_landscape_orientation()
		require("app.core.platform.window").apply_mobile_window()
	end

	G:launch()
	Dictionary.load()

	if os_name == "iOS" or os_name == "Android" then
		require("app.core.platform.window").sync_resize()
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

		---@cast result LuaSteam|nil
		if ok and result and result.init and result:init() then
			result.send_control = {
				last_sent_time = -200,
				last_sent_stage = -1,
				force = false,
			}
			G.STEAM = result
		else
			print("Steam not available — running without Steam integration")
			G.STEAM = nil
		end
	end

	love.mouse.setVisible(false)
end

--- Stops background services before the process exits.
function love.quit()
	if G.AUDIO_WORKER then
		G.AUDIO_WORKER.channel:push({ op = "stop" })
	end
	if G.STEAM then
		G.STEAM:shutdown()
	end
end

---@param dt number
function love.update(dt)
	perf_checkpoint(nil, "update", true)
	G:update(dt)
end

function love.draw()
	perf_checkpoint(nil, "draw", true)
	G:draw()
end

return true
