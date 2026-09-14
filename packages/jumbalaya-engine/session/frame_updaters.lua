--[[
	jumbalaya-engine/session/frame_updaters.lua - Engine-owned Game:update hooks.

	Registered once when loop.lua loads. Game-specific hooks stay in
	app/bootstrap/runtime_boot.lua.
]]

local Updaters = require("jumbalaya-engine.session.updaters")
local save_queue = require("jumbalaya-engine.persistence.save_queue")
local mix_audio = require("jumbalaya-engine.sound.sound").mix_audio

Updaters.register("early_frame", "mix_audio", function(_, dt)
	mix_audio(dt)
end)

Updaters.register("early_frame", "wall_clock", function(game, dt)
	game.TIMERS.REAL = game.TIMERS.REAL + dt
	game.TIMERS.UPTIME = game.TIMERS.UPTIME + dt
	game.SETTINGS.DEMO.total_uptime = (game.SETTINGS.DEMO.total_uptime or 0) + dt
	game.TIMERS.BACKGROUND = game.TIMERS.BACKGROUND + dt * (game.ARGS.spin and game.ARGS.spin.amount or 0)
	game.real_dt = dt
end)

Updaters.register("simulation", "ambient_colours", function(game)
	game.C.DARK_FINISH[1] = 0.6 + 0.2 * math.sin(game.TIMERS.REAL * 1.3)
	game.C.DARK_FINISH[3] = 0.6 + 0.2 * (1 - math.sin(game.TIMERS.REAL * 1.3))
	game.C.DARK_FINISH[2] = math.min(game.C.DARK_FINISH[3], game.C.DARK_FINISH[1])

	game.C.FINISH[1] = 0.7 + 0.2 * (1 + math.sin(game.TIMERS.REAL * 1.5 + 0))
	game.C.FINISH[3] = 0.7 + 0.2 * (1 + math.sin(game.TIMERS.REAL * 1.5 + 3))
	game.C.FINISH[2] = 0.7 + 0.2 * (1 + math.sin(game.TIMERS.REAL * 1.5 + 6))
end)

Updaters.register("simulation", "engine_timeline", function(game)
	if game.TIMELINE and game.TIMELINE.advance then
		game.TIMELINE:advance(game.real_dt)
	end
end)

Updaters.register("post_input", "steam_stats", function(game)
	if not game.STEAM or not game.STEAM.send_control.update_queued then return end
	if not (
		game.STEAM.send_control.force
		or game.STEAM.send_control.last_sent_stage ~= game.STAGE
		or game.STEAM.send_control.last_sent_time < game.TIMERS.UPTIME - 120
	) then
		return
	end
	if game.STEAM.userStats.storeStats() then
		game.STEAM.send_control.force = false
		game.STEAM.send_control.last_sent_stage = game.STAGE
		game.STEAM.send_control.last_sent_time = game.TIMERS.UPTIME
		game.STEAM.send_control.update_queued = false
	else
		game.DEBUG_VALUE = "UNABLE TO STORE STEAM STATS"
	end
end)

Updaters.register("post_input", "save_queue", function()
	save_queue.update()
end)

return true
