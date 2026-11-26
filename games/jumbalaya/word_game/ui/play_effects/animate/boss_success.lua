--[[ word_game/ui/play_effects/animate/boss_success.lua - Boss word cleared sequence ]]

local game = require("word_game.ui.util.game_runtime").game
local facade = require("word_game.ui.facade")
local word_feedback = require("word_game.ui.feedback.word_feedback")
local definition = require("word_game.ui.play_effects.definition")
local context = require("word_game.ui.play_effects.animate.context")
local play_sfx = require("jumbalaya-engine.sound.sound").play_sfx

local bonus_stack_ui = facade.bonus_stack_ui()

local M = {}

function M.present_boss_word_success(jumble, j, used_cards, on_hand_cleared, on_complete)
	local WELL_DONE_HOLD = 1.0
	local CARD_DELAY = 0.45
	local CARD_STAGGER = 0.07
	local STACK_HOLD = 0.3

	local live = (jumble and jumble.state and jumble.state()) or j
	j = live or j

	definition.set_word_score_animating(true)
	if WORD_GAME_UI.TimelineTimer and WORD_GAME_UI.TimelineTimer.pause then
		WORD_GAME_UI.TimelineTimer.pause()
	end

	local cards = bonus_stack_ui.gutter_cards_for_boss_clear(j, used_cards)
	for _, card in ipairs(cards) do
		bonus_stack_ui.detach(card)
	end
	if j and j.slots then
		jumble.clear_blank_cards(j.slots)
		jumble.sync_placement_cards(j.slots)
	end
	bonus_stack_ui.stage_cards(cards)

	local function finish_success()
		bonus_stack_ui.promote_to_bonus(cards)
		if on_hand_cleared then
			on_hand_cleared({ boss_cleared = true })
		end
		if on_complete then
			on_complete({ word = j.puzzle and j.puzzle.boss_word, boss = true })
		end
	end

	context.effects().queue_event(Tween({
		mode = "delayed",
		delay = 0.05,
		blocking = false,
		func = function()
			if not word_feedback.show_boss_center_text("Well done!", WELL_DONE_HOLD, "title") then
				word_feedback.show_screen_centered(
					"Well done!",
					(game().C and game().C.GOLD) or { 1, 0.8, 0, 1 },
					WELL_DONE_HOLD
				)
			end
			if play_sfx then
				play_sfx("coin2", 1, 0.9)
			end
			return true
		end,
	}))

	bonus_stack_ui.animate_cards_to_stack(context.effects().queue_event, nil, {
		initial_delay = 0,
		card_delay = CARD_DELAY,
		stagger = CARD_STAGGER,
		hold = STACK_HOLD,
		on_complete = finish_success,
	})
end

return M