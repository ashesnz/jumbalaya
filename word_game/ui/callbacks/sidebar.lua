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
	G.FUNCS.character_intro_next = function()
		if WORD_GAME and WORD_GAME.PlayerHost then
			WORD_GAME.PlayerHost.advance_intro()
		end
	end
	G.FUNCS.stage3_ally_next = function()
		if WORD_GAME and WORD_GAME.PlayerHost then
			WORD_GAME.PlayerHost.advance_stage3_ally()
		end
	end
	G.FUNCS.perk_stamp_demo = function()
		if WORD_GAME and WORD_GAME.PerkStamp then
			WORD_GAME.PerkStamp.debug_step()
		end
	end
end
