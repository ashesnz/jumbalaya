--[[ word_game/ui/sidebar/funcs.lua - Sidebar G.FUNCS registration (logic on Sidebar module) ]]

local SidebarController = require("word_game.ui.controllers.sidebar")

return function(sidebar)
	local bindings = SidebarController.bind(sidebar)
	G.FUNCS.ensure_table_board_sidebar = bindings.ensure_table_board_sidebar
	G.FUNCS.rebuild_table_board_sidebar = bindings.rebuild_table_board_sidebar
	G.FUNCS.end_run_from_sidebar = bindings.end_run_from_sidebar
	G.FUNCS.classic_stage_next = bindings.classic_stage_next
end
