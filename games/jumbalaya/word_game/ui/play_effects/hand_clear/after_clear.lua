--[[ word_game/ui/play_effects/hand_clear/after_clear.lua - Route stage-clear outcomes ]]

local facade = require("word_game.ui.facade")

local Deck = facade.deck()
local Jumble = facade.jumble()
local game_access = facade.game_access()

local M = {}

function M.handle_after_clear(play_module, opts, outcome, set_score_animating)
	if WORD_GAME_UI.HandClearFocus and WORD_GAME_UI.HandClearFocus.end_focus then
		WORD_GAME_UI.HandClearFocus.end_focus()
	end
	set_score_animating(false)

	if outcome == "win" then
		play_module.end_match(true)
		return
	end
	if outcome == "boss_bonus_hand" then
		local wr = game_access.word_round()
		local bonus_stack = WORD_GAME_UI.BonusStackUI
		if bonus_stack and bonus_stack.finalize_for_bonus_hand then
			bonus_stack.finalize_for_bonus_hand(wr)
		end
		if WORD_GAME_UI.PlayEffects and WORD_GAME_UI.PlayEffects.restore_boss_layout then
			WORD_GAME_UI.PlayEffects.restore_boss_layout({ keep_bonus_stack = true })
		end
		if WORD_GAME_UI.ScoreBanner and WORD_GAME_UI.ScoreBanner.set_banner_mode then
			WORD_GAME_UI.ScoreBanner.set_banner_mode("normal")
		end
		play_module.begin_next_hand_after_boss()
		return
	end
	if outcome == "boss_hand_advanced" then
		if Deck.destroy_boss_cards then
			Deck.destroy_boss_cards()
		end
		if WORD_GAME_UI.PlayEffects and WORD_GAME_UI.PlayEffects.restore_boss_layout then
			WORD_GAME_UI.PlayEffects.restore_boss_layout()
		end
		if WORD_GAME_UI.ScoreBanner and WORD_GAME_UI.ScoreBanner.set_banner_mode then
			WORD_GAME_UI.ScoreBanner.set_banner_mode("normal")
		end
		play_module.begin_next_hand_after_boss()
		return
	end
	if outcome == "boss_next" then
		local wr = game_access.word_round()
		if Jumble.begin_boss_word then
			Jumble.begin_boss_word(wr, function()
				set_score_animating(false)
			end)
		end
		return
	end
	if outcome == "trade" then
		WORD_GAME_UI.TradeUI.open_then_dealer()
		return
	end
	if outcome == "dealer" then
		play_module.continue_after_dealer()
	end
end

return M
