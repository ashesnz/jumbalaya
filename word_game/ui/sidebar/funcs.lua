--[[ word_game/ui/sidebar/funcs.lua - Sidebar runtime().FUNCS registration (logic on Sidebar module) ]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local SidebarController = require("word_game.ui.controllers.sidebar")

return function(sidebar)
	local bindings = SidebarController.bind(sidebar)
	runtime().FUNCS.ensure_table_board_sidebar = bindings.ensure_table_board_sidebar
	runtime().FUNCS.rebuild_table_board_sidebar = bindings.rebuild_table_board_sidebar
	runtime().FUNCS.end_run_from_sidebar = bindings.end_run_from_sidebar
	runtime().FUNCS.classic_stage_next = bindings.classic_stage_next
end
