--[[
	word_game/ui/play_effects/animate/init.lua — Timed play sequences and card choreography.
	Inputs: jumble state, play result, TIMELINE, card_fly_off, boss_word_intro.
	Outputs: present_jumble_next, present_word_play_after_cards, present_boss_word_*.
]]

local boss_word_intro = require("word_game.ui.play_effects.boss_word_intro")
local definition = require("word_game.ui.play_effects.definition")
local word_feedback = require("word_game.ui.feedback.word_feedback")
local round_config = require("jumbalaya_core.config.gameplay.round")
local context = require("word_game.ui.play_effects.animate.context")
local cards = require("word_game.ui.play_effects.animate.cards")
local boss_success = require("word_game.ui.play_effects.animate.boss_success")
local word_play = require("word_game.ui.play_effects.animate.word_play")
local jumble_next = require("word_game.ui.play_effects.animate.jumble_next")

local M = {}

boss_word_intro.bind({
	definition = definition,
	word_feedback = word_feedback,
	round_config = round_config,
	effects = function()
		return context.effects()
	end,
})

function M.bind_host(mod)
	context.bind_host(mod)
end

function M.run_card_return_sequence(used_cards, on_after, return_to_deck)
	cards.run_card_return_sequence(used_cards, on_after, return_to_deck)
end

function M.deal_and_refresh(on_complete)
	cards.deal_and_refresh(on_complete)
end

function M.present_boss_word(wr, on_complete)
	boss_word_intro.present_boss_word(wr, on_complete)
end

function M.present_boss_word_success(jumble, j, used_cards, on_hand_cleared, on_complete)
	boss_success.present_boss_word_success(jumble, j, used_cards, on_hand_cleared, on_complete)
end

function M.present_word_play_after_cards(jumble, j, result, on_hand_cleared, on_complete)
	word_play.present_word_play_after_cards(jumble, j, result, on_hand_cleared, on_complete)
end

function M.present_jumble_next(jumble, wr, opts)
	jumble_next.present_jumble_next(jumble, wr, opts)
end

function M.present_end_jumble_sidebar()
	jumble_next.present_end_jumble_sidebar()
end

return M
