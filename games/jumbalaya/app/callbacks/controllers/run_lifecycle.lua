--[[ app/controllers/run_lifecycle.lua - Phase 4 run start / menu return controller ]]

local BridgeRuntime = require("app.runtime")
local function game_access() return BridgeRuntime.game_access() end
local function game() return BridgeRuntime.game() end

local M = {}

function M.notify_then_start_run(_e)
	-- Overlay click nodes die with OVERLAY_MENU; never pass them into begin_run.
	local overlays = require("app.callbacks.controllers.overlays")
	overlays.close_overlay()
	M.begin_run(nil)
end

function M.begin_run(e, args)
	game().SETTINGS.paused = false
	local config = e and (rawget(e, "config") or e.config)
	if config and config.id == 'restart_button' then game_access().patch({ viewed_back = nil }) end
	game().TIMELINE:flush()
	game():discard_run()
	game():start_run(args)
	game():start_gameplay_board()
end

function M.begin_classic_run(e)
	M.begin_run(e, { run_mode = "classic" })
end

function M.begin_time_run(e)
	M.begin_run(e, { run_mode = "time_run" })
end

function M.return_to_menu(e)
	game():queue_wipe_transition({
		function()
			game():discard_run()
			return true
		end,
		{
			blockable = true,
			blocking = false,
			func = function()
				game():open_main_menu('game')
				return true
			end,
		},
	}, { flush_timeline = true, pause = true })
end

return M
