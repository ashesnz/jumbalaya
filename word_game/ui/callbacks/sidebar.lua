--[[ word_game/ui/callbacks/sidebar.lua - Vault sidebar G.FUNCS (bound via sidebar:install) ]]

return function(sidebar, hud_definition)
	G.FUNCS.ensure_table_board_sidebar = function()
		sidebar:ensure()
	end
	G.FUNCS.rebuild_table_board_sidebar = function()
		if G.VAULT_HUD then
			hud_definition.relayout_vault()
		else
			sidebar:ensure()
		end
	end
	G.FUNCS.end_run_from_vault = function()
		local vault_btn = WORD_GAME and WORD_GAME.VaultStageButton
		if vault_btn and vault_btn.press then
			vault_btn.press()
			return
		end
		local voucher_discard = WORD_GAME and WORD_GAME.VoucherDiscard
		if voucher_discard and voucher_discard.end_run then
			voucher_discard.end_run()
		end
	end
	G.FUNCS.classic_stage_next = function()
		local vault_btn = WORD_GAME and WORD_GAME.VaultStageButton
		if vault_btn and vault_btn.collect_and_advance then
			vault_btn.collect_and_advance()
		end
	end
end
