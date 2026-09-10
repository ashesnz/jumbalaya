--[[ word_game/ui/sidebar/funcs.lua - Sidebar G.FUNCS registration (logic on Sidebar module) ]]

return function(sidebar)
	G.FUNCS.ensure_table_board_sidebar = sidebar.ensure_table_board
	G.FUNCS.rebuild_table_board_sidebar = sidebar.rebuild
	G.FUNCS.end_run_from_sidebar = sidebar.end_run
	G.FUNCS.classic_stage_next = sidebar.classic_stage_next
end
