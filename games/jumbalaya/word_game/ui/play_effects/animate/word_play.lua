--[[ word_game/ui/play_effects/animate/word_play.lua - Post-word card choreography ]]

local facade = require("word_game.ui.facade")
local definition = require("word_game.ui.play_effects.definition")
local cards = require("word_game.ui.play_effects.animate.cards")
local boss_success = require("word_game.ui.play_effects.animate.boss_success")

local RunMode = facade.run_mode()

local M = {}

function M.present_word_play_after_cards(jumble, j, result, on_hand_cleared, on_complete)
	local is_boss_success = j.boss_word_active
		and result.word == (j.puzzle and j.puzzle.boss_word)
	local end_hand = result.cleared and RunMode.ends_hand_on_target()

	local function after_cards_cleared()
		jumble.clear_blank_cards(j.slots)
		jumble.sync_placement_cards(j.slots)
		if end_hand then
			j.total_score = result.new_score
			definition.add_points(result.word_pts)
			definition.set_word_score_animating(true)
			definition.align_placement_table()
			on_hand_cleared()
			if on_complete then
				on_complete({ word = result.word, points = result.new_pts, multi = result.new_multi })
			end
		else
			cards.deal_and_refresh(function()
				definition.show_word_success(result.word)
				definition.sync_hand_controls()
				if on_complete then
					on_complete({ word = result.word, points = result.new_pts, multi = result.new_multi })
				end
			end)
		end
	end

	if end_hand then
		definition.set_word_score_animating(true)
	end

	if definition.triggers_boss_word(result) and end_hand then
		cards.finish_used_cards(result.used_cards, true)
		after_cards_cleared()
		return
	end

	if is_boss_success then
		boss_success.present_boss_word_success(jumble, j, result.used_cards, on_hand_cleared, on_complete)
		return
	end

	cards.run_card_return_sequence(result.used_cards, after_cards_cleared, true)
end

return M
