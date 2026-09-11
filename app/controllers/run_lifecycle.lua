--[[ app/controllers/run_lifecycle.lua - Phase 4 run start / menu return controller ]]

local game_access = require("word_game.model.game_access")

local M = {}

function M.notify_then_start_run(e)
	G.OVERLAY_MENU:remove()
	G.OVERLAY_MENU = nil
	M.begin_run(e)
end

function M.begin_run(e, args)
	G.SETTINGS.paused = false
	if e and e.config.id == 'restart_button' then game_access.patch({ viewed_back = nil }) end
	G.TIMELINE:flush()
	G:queue_during_wipe(function()
		G:discard_run()
		G:start_run(args)
		G:start_gameplay_board()
	end)
end

function M.begin_classic_run(e)
	M.begin_run(e, { run_mode = "classic" })
end

function M.begin_time_run(e)
	M.begin_run(e, { run_mode = "time_run" })
end

function M.return_to_menu(e)
	G:queue_wipe_transition({
		function()
			G:discard_run()
			return true
		end,
		{
			blockable = true,
			blocking = false,
			func = function()
				G:open_main_menu('game')
				return true
			end,
		},
	}, { flush_timeline = true, pause = true })
end

return M
