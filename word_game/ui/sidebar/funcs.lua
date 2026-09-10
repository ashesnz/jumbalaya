--[[ word_game/ui/sidebar/funcs.lua - Sidebar G.FUNCS (bound via sidebar:install) ]]

return function(sidebar, hud_definition)
	G.FUNCS.ensure_table_board_sidebar = function()
		sidebar:ensure()
	end
	G.FUNCS.rebuild_table_board_sidebar = function()
		if G.SIDEBAR_HUD then
			hud_definition.relayout()
		else
			sidebar:ensure()
		end
	end
	G.FUNCS.end_run_from_sidebar = function()
		local stage_btn = WORD_GAME and WORD_GAME_UI.SidebarStageButton
		if stage_btn and stage_btn.press then
			stage_btn.press()
			return
		end
		local voucher_discard = WORD_GAME and WORD_GAME_UI.VoucherDiscard
		if voucher_discard and voucher_discard.end_run then
			voucher_discard.end_run()
		end
	end
	G.FUNCS.classic_stage_next = function()
		local stage_btn = WORD_GAME and WORD_GAME_UI.SidebarStageButton
		if stage_btn and stage_btn.collect_and_advance then
			stage_btn.collect_and_advance()
		end
	end
end
