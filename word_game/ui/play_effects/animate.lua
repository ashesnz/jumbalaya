--[[ word_game/ui/play_effects/animate.lua - Play motion sequences and card choreography ]]

local M = {}

local facade = require("word_game.ui.facade")
local word_feedback = require("word_game.ui.feedback.word_feedback")
local bonus_stack_ui = facade.bonus_stack_ui()
local card_fly_off = require("word_game.ui.play_effects.card_fly_off")
local jumble_fixed_letters = require("word_game.ui.table.jumble_fixed_letters")
local round_config = require("word_game.config.gameplay.round")
local Easing = require "app.effects.easing"
local definition = require("word_game.ui.play_effects.definition")
local boss_word_intro = require("word_game.ui.play_effects.boss_word_intro")

local host

local function effects()
	return host
end

boss_word_intro.bind({
	definition = definition,
	word_feedback = word_feedback,
	round_config = round_config,
	effects = effects,
})

local RunMode = facade.run_mode()

local function deck_api()
	return facade.deck()
end

function M.bind_host(mod)
	host = mod
end

local function has_event_manager()
	return G.TIMELINE and G.TIMELINE.enqueue
end

local function finish_used_card(card, return_to_deck)
	if bonus_stack_ui.is_bonus_card(card) then
		if card.area then
			card.area:remove_card(card)
		end
		bonus_stack_ui.consume_card(card)
	elseif return_to_deck then
		if card.area then
			card.area:remove_card(card)
		end
		card_fly_off.stash_played_card(card)
	else
		if card.area then
			card.area:remove_card(card)
		end
		deck_api().destroy_card(card)
	end
end

local function finish_used_cards(used_cards, return_to_deck)
	definition.show_bonus_flyovers(used_cards)
	local returned = false
	for _, card in ipairs(used_cards or {}) do
		if not bonus_stack_ui.is_bonus_card(card) and return_to_deck then
			returned = true
		end
		finish_used_card(card, return_to_deck)
	end
	if returned then
		deck_api().sync_deck_count_display()
	end
end

function M.run_card_return_sequence(used_cards, on_after, return_to_deck)
	definition.show_bonus_flyovers(used_cards)
	card_fly_off.fly_cards_off(used_cards, effects().queue_event, {
		return_to_deck = return_to_deck,
		on_complete = function()
			deck_api().sync_deck_count_display()
			if on_after then on_after() end
		end,
	})
end

function M.deal_and_refresh(on_complete)
	local function finish()
		effects().request_layout_refresh()
		definition.sync_hand_after_deal()
		if on_complete then on_complete() end
	end
	if deck_api().is_jumble_deck and deck_api().is_jumble_deck()
		and deck_api().needs_jumble_reshuffle and deck_api().needs_jumble_reshuffle() then
		deck_api().try_jumble_reshuffle_and_deal(finish)
		return
	end
	deck_api().deal_into_hand(facade.hand_size().get(), finish)
end

function M.present_boss_word(wr, on_complete)
	boss_word_intro.present_boss_word(wr, on_complete)
end

local function detach_card_for_stack(card)
	bonus_stack_ui.detach(card)
end

function M.present_boss_word_success(jumble, j, used_cards, on_hand_cleared, on_complete)
	local WELL_DONE_HOLD = 1.0
	local CARD_DELAY = 0.45
	local CARD_STAGGER = 0.07
	local STACK_HOLD = 0.3

	definition.set_word_score_animating(true)
	if WORD_GAME_UI.TimelineTimer and WORD_GAME_UI.TimelineTimer.pause then
		WORD_GAME_UI.TimelineTimer.pause()
	end

	local cards = {}
	for _, card in ipairs(used_cards or {}) do
		detach_card_for_stack(card)
		cards[#cards + 1] = card
	end
	jumble.clear_blank_cards(j.slots)
	jumble.sync_placement_cards(j.slots)
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

	effects().queue_event(Tween({
		mode = "delayed",
		delay = 0.05,
		blocking = true,
		func = function()
			word_feedback.show_screen_centered("Well done!", G.C.GOLD, WELL_DONE_HOLD)
			if play_sfx then
				play_sfx("coin2", 1, 0.9)
			end
			return true
		end,
	}))

	bonus_stack_ui.animate_cards_to_stack(effects().queue_event, nil, {
		initial_delay = 0,
		card_delay = CARD_DELAY,
		stagger = CARD_STAGGER,
		hold = STACK_HOLD,
		on_complete = finish_success,
	})
end

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
			M.deal_and_refresh(function()
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
		finish_used_cards(result.used_cards, true)
		after_cards_cleared()
		return
	end

	if is_boss_success then
		M.present_boss_word_success(jumble, j, result.used_cards, on_hand_cleared, on_complete)
		return
	end

	-- Jumble word plays always return used cards to the deck (gameplay.md §Playing a puzzle).
	-- Stage target reached is handled separately via on_hand_cleared → populate_jumble_deck_api().
	M.run_card_return_sequence(result.used_cards, after_cards_cleared, true)
end

function M.present_jumble_next(jumble, wr, opts)
	local jl = jumble_fixed_letters
	definition.set_word_score_animating(true)
	if play_sfx then play_sfx("card_slide1", 0.85, 0.7) end

	local anim = jl.anim_state()
	if has_event_manager() and not (opts and opts.instant) then
		jl.set_anim({ offset_y = 0, alpha = 1 })
		Easing.value{ref_table = anim, ref_value = "offset_y", mod = -4.0, timer = "REAL", not_blockable = false, delay = 0.22, ease = "quad"}
		Easing.value{ref_table = anim, ref_value = "alpha", mod = -1.0, timer = "REAL", not_blockable = false, delay = 0.22, ease = "quad"}

		effects().queue_event(Tween({
			mode = "delayed",
			delay = 0.24,
			blocking = true,
			func = function()
				jumble.advance_puzzle(wr)
				jl.set_anim({ offset_y = 4.0, alpha = 0 })
				Easing.value{ref_table = anim, ref_value = "offset_y", mod = -4.0, timer = "REAL", not_blockable = false, delay = 0.22, ease = "quad"}
				Easing.value{ref_table = anim, ref_value = "alpha", mod = 1.0, timer = "REAL", not_blockable = false, delay = 0.22, ease = "quad"}
				if play_sfx then play_sfx("card_slide1", 1.05, 0.7) end
				return true
			end,
		}))

		effects().queue_event(Tween({
			mode = "delayed",
			delay = 0.24,
			blocking = true,
			func = function()
				jl.reset_anim()
				definition.set_word_score_animating(false)
				definition.sync_hand_controls()
				if opts and opts.on_complete then
					opts.on_complete()
				end
				return true
			end,
		}))
	else
		jumble.advance_puzzle(wr)
		jl.reset_anim()
		definition.set_word_score_animating(false)
		if opts and opts.on_complete then
			opts.on_complete()
		end
	end
end

function M.present_end_jumble_sidebar()
	definition.sync_hand_controls()
	if WORD_GAME_UI.Sidebar then
		WORD_GAME_UI.Sidebar:refresh()
	end
end

return M
