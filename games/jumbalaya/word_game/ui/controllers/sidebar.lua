--[[ word_game/ui/controllers/sidebar.lua - Phase 4 sidebar game().FUNCS controller ]]

local game = require("word_game.ui.util.game_runtime").game

local action_dispatch = require("app.input.action_dispatch")

local M = {}

function M.bind(sidebar)
	return {
		ensure_table_board_sidebar = sidebar.ensure_table_board,
		rebuild_table_board_sidebar = sidebar.rebuild,
		end_run_from_sidebar = function(...)
			action_dispatch.dispatch_func("end_run_from_sidebar")
			return sidebar.end_run(...)
		end,
		classic_stage_next = function(...)
			action_dispatch.dispatch_func("classic_stage_next")
			return sidebar.classic_stage_next(...)
		end,
	}
end

return M
