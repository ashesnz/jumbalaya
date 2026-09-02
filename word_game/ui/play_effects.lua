--[[ word_game/ui/play_effects.lua - Play-button UI orchestration (sounds, banners, events) ]]

local M = {}

local deck = require("word_game.model.cards.deck")
local word_feedback = require("word_game.ui.word_feedback")
local boss_word_stack = require("word_game.ui.boss_word_stack")
local card_fly_off = require("word_game.ui.card_fly_off")
local round_config = require("word_game.config.round_config")
local hand_size_cfg = require("word_game.config.hand_size")
local Easing = require "app.effects.easing"
local Scheduler = require "app.effects.scheduler"

local function has_event_manager()
	return G.TIMELINE and G.TIMELINE.enqueue
end

function M.queue_event(ev)
	if has_event_manager() then
		Scheduler.add{event = ev}
	elseif ev and ev.func then
		ev.func()
	end
end

function M.request_layout_refresh()
	G.ARGS = G.ARGS or {}
	G.ARGS.pending_layout = true
end

function M.capture_token_timer_if_cleared(cleared, opts)
	opts = opts or {}
	if not cleared then return end
	if not opts.skip_focus
		and WORD_GAME and WORD_GAME.HandClearFocus and WORD_GAME.HandClearFocus.begin then
		WORD_GAME.HandClearFocus.begin()
	end
	if WORD_GAME and WORD_GAME.TokenReward and WORD_GAME.TokenReward.capture_timer then
		WORD_GAME.TokenReward.capture_timer()
	end
end

function M.triggers_boss_word(result)
	if not result or not result.cleared then return false end
	local wr = G.GAME and G.GAME.word_round
	local j = wr and wr.jumble
	return wr and round_config.is_boss_word_hand(wr.set, wr.hand_index)
		and j and not j.boss_word_active and not j.boss_word_staging
end

function M.roll_jumble_banners(result)
	if not (WORD_GAME and WORD_GAME.ScoreBanner) then return end
	if M.triggers_boss_word(result) then
		if WORD_GAME.ScoreBanner.hide_points_to_get_display then
			WORD_GAME.ScoreBanner.hide_points_to_get_display()
		end
		if result.kind == "word_play" and WORD_GAME.ScoreBanner.roll_jumble_score then
			WORD_GAME.ScoreBanner.roll_jumble_score(
				result.old_pts, result.new_pts, result.old_multi, result.new_multi
			)
		end
		return
	end
	if result.kind == "word_play" then
		if WORD_GAME.ScoreBanner.roll_jumble_score then
			WORD_GAME.ScoreBanner.roll_jumble_score(
				result.old_pts, result.new_pts, result.old_multi, result.new_multi
			)
		end
	end
	if result.cleared then
		if WORD_GAME.ScoreBanner.hide_points_to_get_display then
			WORD_GAME.ScoreBanner.hide_points_to_get_display()
		end
	elseif WORD_GAME.ScoreBanner.roll_points_to_get then
		WORD_GAME.ScoreBanner.roll_points_to_get(result.old_rem, result.new_rem, 0.4)
	end
end

function M.show_validation_error(err)
	if word_feedback.is_invalid_reason(err) then
		word_feedback.show_invalid()
	else
		word_feedback.show(err or "Cannot play", G.C.RED)
	end
	play_sfx("cancel", 0.8, 0.6)
end

function M.set_word_score_animating(active)
	if G.GAME then
		G.GAME.word_score_animating = active
	end
end

function M.add_points(amount)
	if G.GAME then
		G.GAME.points = (G.GAME.points or 0) + amount
	end
end

function M.sync_hand_after_deal()
	if G.hand and G.hand.cards[1] then
		G.hand:relayout()
		for _, card in ipairs(G.hand.cards) do
			if not card.bounce and card.states and not card.states.drag.is then
				card:hard_set_T()
			end
		end
		if G.hand.velocity then
			G.hand.velocity.x = 0
			G.hand.velocity.y = 0
			G.hand.velocity.r = 0
			G.hand.velocity.scale = 0
		end
		G.hand:snap_VT()
	end
	if WORD_GAME and WORD_GAME.HandShuffle then
		WORD_GAME.HandShuffle.sync_position()
	end
end

function M.align_placement_table()
	if G.placement_table and G.placement_table.area then
		G.placement_table:relayout()
		G.placement_table.area:hard_set_cards()
	end
end

function M.show_word_success(word)
	word_feedback.show(word .. "  +" .. #word, G.C.GREEN, 1.2, 0.35)
	play_sfx("coin2", 1, 0.9)
end

function M.show_puzzle_bank_feedback(puzzle_total)
	word_feedback.show(puzzle_total .. " Points Scored!", G.C.GOLD, 1.5, 0.35)
	play_sfx("coin2", 1, 0.9)
end

function M.sync_sidebar_actions()
	if WORD_GAME and WORD_GAME.Sidebar then
		WORD_GAME.Sidebar.sync_action_buttons()
	end
end

function M.restore_boss_layout(opts)
	opts = opts or {}
	if not opts.keep_bonus_stack then
		boss_word_stack.clear()
	end
	local wr = G.GAME and G.GAME.word_round
	if wr and wr.jumble then
		wr.jumble.locked_hand_layout = nil
	end
	if WORD_GAME and WORD_GAME.Layout then
		WORD_GAME.Layout.update_all()
		WORD_GAME.Layout.set_screen_positions()
	end
	if WORD_GAME and WORD_GAME.Sidebar and WORD_GAME.Sidebar.sync_visibility then
		WORD_GAME.Sidebar.sync_visibility()
	end
	M.request_layout_refresh()
	M.align_placement_table()
	if G.hand then
		G.hand:relayout()
		G.hand:snap_VT()
		G.hand:hard_set_cards()
	end
	if WORD_GAME and WORD_GAME.HandShuffle then
		WORD_GAME.HandShuffle.sync_position()
	end
	if opts.keep_bonus_stack and boss_word_stack.sync_positions
		and not boss_word_stack.is_animating() then
		boss_word_stack.sync_positions()
	end
end

function M.show_bonus_flyovers(used_cards)
	local FloatUp = WORD_GAME and WORD_GAME.FloatUpText
	if not FloatUp or not FloatUp.from_card then return end
	for _, card in ipairs(used_cards or {}) do
		if boss_word_stack.is_bonus_card(card) then
			FloatUp.from_card(card, "+" .. tostring(boss_word_stack.BONUS_POINTS), {
				colour = G.C and G.C.GOLD or { 1, 0.85, 0.2, 1 },
			})
		end
	end
end

function M.run_card_return_sequence(used_cards, on_after, return_to_deck)
	M.show_bonus_flyovers(used_cards)
	card_fly_off.fly_cards_off(used_cards, M.queue_event, {
		return_to_deck = return_to_deck,
		on_complete = function()
			deck.sync_deck_count_display()
			if on_after then on_after() end
		end,
	})
end

local function finish_used_card(card, return_to_deck)
	if boss_word_stack.is_bonus_card(card) then
		if card.area then
			card.area:remove_card(card)
		end
		boss_word_stack.consume_card(card)
	elseif return_to_deck then
		if card.area then
			card.area:remove_card(card)
		end
		card_fly_off.stash_played_card(card)
	else
		if card.area then
			card.area:remove_card(card)
		end
		deck.destroy_card(card)
	end
end

local function finish_used_cards(used_cards, return_to_deck)
	M.show_bonus_flyovers(used_cards)
	local returned = false
	for _, card in ipairs(used_cards or {}) do
		if not boss_word_stack.is_bonus_card(card) and return_to_deck then
			returned = true
		end
		finish_used_card(card, return_to_deck)
	end
	if returned then
		deck.sync_deck_count_display()
	end
end

function M.deal_and_refresh(on_complete)
	local function finish()
		M.request_layout_refresh()
		M.sync_hand_after_deal()
		if on_complete then on_complete() end
	end
	if deck.is_jumble_deck and deck.is_jumble_deck()
		and deck.needs_jumble_reshuffle and deck.needs_jumble_reshuffle() then
		deck.try_jumble_reshuffle_and_deal(finish)
		return
	end
	deck.deal_into_hand(hand_size_cfg.get(), finish)
end

function M.present_boss_word(wr, on_complete)
	local jumble = WORD_GAME and WORD_GAME.Jumble
	local deck_mod = WORD_GAME and WORD_GAME.Deck
	if not wr or not jumble or not deck_mod then
		if on_complete then on_complete() end
		return
	end

	if G.hand and wr.jumble then
		wr.jumble.locked_hand_layout = nil
	end

	M.set_word_score_animating(true)
	if WORD_GAME.ScoreBanner and WORD_GAME.ScoreBanner.hide_points_to_get_display then
		WORD_GAME.ScoreBanner.hide_points_to_get_display()
	end
	if WORD_GAME.TimelineTimer and WORD_GAME.TimelineTimer.pause then
		WORD_GAME.TimelineTimer.pause()
	end

	local function run_countdown(done)
		if WORD_GAME and WORD_GAME.ScoreBanner and WORD_GAME.ScoreBanner.set_banner_mode then
			WORD_GAME.ScoreBanner.set_banner_mode("boss_word", "BOSS WORD")
		end

		local steps = {
			{ text = "Are you ready?", hold = 1.0, delay = 0.15 },
			{ text = "3", hold = 0.75, delay = 0 },
			{ text = "2", hold = 0.75, delay = 0 },
			{ text = "1", hold = 0.75, delay = 0 },
			{ text = "Go!", hold = 0.6, delay = 0 },
		}

		local function queue_step(index)
			if index > #steps then
				M.queue_event(Tween({
					mode = "delayed",
					delay = 0.15,
					blocking = true,
					func = function()
						if done then done() end
						return true
					end,
				}))
				return
			end
			local step = steps[index]
			M.queue_event(Tween({
				mode = "delayed",
				delay = step.delay,
				blocking = true,
				func = function()
					word_feedback.show_above_hand_centered(step.text, G.C.GOLD, step.hold)
					if step.text == "1"
						and WORD_GAME and WORD_GAME.BossWordAnnounce
						and WORD_GAME.BossWordAnnounce.play_theme then
						WORD_GAME.BossWordAnnounce.play_theme("Garden Theme")
					end
					if play_sfx then
						if index == 1 then
							play_sfx("timpani", 0.9, 0.7)
						elseif index == #steps then
							play_sfx("coin2", 0.95, 0.85)
						else
							play_sfx("card_tick", 0.9, 0.7)
						end
					end
					M.queue_event(Tween({
						mode = "delayed",
						delay = step.hold,
						blocking = true,
						func = function()
							queue_step(index + 1)
							return true
						end,
					}))
					return true
				end,
			}))
		end

		queue_step(1)
	end

	local function after_boss_deal()
		run_countdown(function()
			if wr.jumble then
				wr.jumble.boss_word_staging = false
			end
			if WORD_GAME and WORD_GAME.Round and WORD_GAME.Round.reset_timeline then
				WORD_GAME.Round.reset_timeline()
			end
			if not jumble.reveal_boss_puzzle(wr) then
				M.set_word_score_animating(false)
				if on_complete then on_complete() end
				return
			end
			if WORD_GAME and WORD_GAME.Layout and WORD_GAME.Layout.refresh_placement_layout then
				WORD_GAME.Layout.refresh_placement_layout()
			elseif G.placement_table and G.placement_table.apply_screen_position then
				G.placement_table:apply_screen_position()
			end
			if WORD_GAME and WORD_GAME.Sidebar and WORD_GAME.Sidebar.sync_visibility then
				WORD_GAME.Sidebar.sync_visibility()
			end
			if WORD_GAME and WORD_GAME.HandShuffle then
				WORD_GAME.HandShuffle.sync_position()
			end
			M.request_layout_refresh()
			M.set_word_score_animating(false)
			M.sync_sidebar_actions()
			if on_complete then on_complete() end
		end)
	end

	local function deal_boss_hand()
		if not wr.jumble or not wr.jumble.pending_boss then
			M.set_word_score_animating(false)
			if on_complete then on_complete() end
			return
		end
		local puzzle = wr.jumble.pending_boss
		local letters = jumble.boss_hand_letters(puzzle.boss_word, puzzle.pattern)
		deck_mod.deal_boss_hand(letters, function()
			M.sync_hand_after_deal()
			word_feedback.lock_hand_layout(wr)
			after_boss_deal()
		end, { fast = true })
	end

	if not jumble.prepare_boss_word(wr) then
		M.set_word_score_animating(false)
		if on_complete then on_complete() end
		return
	end
	if WORD_GAME and WORD_GAME.Sidebar and WORD_GAME.Sidebar.sync_visibility then
		WORD_GAME.Sidebar.sync_visibility()
	end

	deck_mod.return_hand_to_deck(function()
		deal_boss_hand()
	end, { instant = true })
end

local function detach_card_for_stack(card)
	boss_word_stack.detach(card)
end

function M.present_boss_word_success(jumble, j, used_cards, on_hand_cleared, on_complete)
	local WELL_DONE_HOLD = 1.0
	local CARD_DELAY = 0.45
	local CARD_STAGGER = 0.07
	local STACK_HOLD = 0.3

	M.set_word_score_animating(true)
	if WORD_GAME and WORD_GAME.TimelineTimer and WORD_GAME.TimelineTimer.pause then
		WORD_GAME.TimelineTimer.pause()
	end

	local cards = {}
	for _, card in ipairs(used_cards or {}) do
		detach_card_for_stack(card)
		cards[#cards + 1] = card
	end
	jumble.clear_blank_cards(j.slots)
	jumble.sync_placement_cards(j.slots)
	boss_word_stack.stage_cards(cards)

	local function finish_success()
		boss_word_stack.promote_to_bonus(cards)
		if on_hand_cleared then
			on_hand_cleared({ boss_cleared = true })
		end
		if on_complete then
			on_complete({ word = j.puzzle and j.puzzle.boss_word, boss = true })
		end
	end

	M.queue_event(Tween({
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

	boss_word_stack.animate_cards_to_stack(M.queue_event, nil, {
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

	local function after_cards_cleared()
		jumble.clear_blank_cards(j.slots)
		jumble.sync_placement_cards(j.slots)
		if result.cleared then
			j.total_score = result.new_score
			M.add_points(result.word_pts)
			M.set_word_score_animating(true)
			M.align_placement_table()
			on_hand_cleared()
			if on_complete then
				on_complete({ word = result.word, points = result.new_pts, multi = result.new_multi })
			end
		else
			M.deal_and_refresh(function()
				M.show_word_success(result.word)
				M.sync_sidebar_actions()
				if on_complete then
					on_complete({ word = result.word, points = result.new_pts, multi = result.new_multi })
				end
			end)
		end
	end

	if result.cleared then
		M.set_word_score_animating(true)
	end

	if M.triggers_boss_word(result) and result.cleared then
		finish_used_cards(result.used_cards, true)
		after_cards_cleared()
		return
	end

	if is_boss_success then
		M.present_boss_word_success(jumble, j, result.used_cards, on_hand_cleared, on_complete)
		return
	end

	-- Jumble word plays always return used cards to the deck (gameplay.md §Playing a puzzle).
	-- Stage target reached is handled separately via on_hand_cleared → populate_jumble_deck.
	M.run_card_return_sequence(result.used_cards, after_cards_cleared, true)
end

function M.present_jumble_next(jumble, wr, opts)
	local jl = require("word_game.ui.jumble_fixed_letters")
	M.set_word_score_animating(true)
	if play_sfx then play_sfx("card_slide1", 0.85, 0.7) end

	local anim = jl.anim_state()
	if has_event_manager() and not (opts and opts.instant) then
		jl.set_anim({ offset_y = 0, alpha = 1 })
		Easing.value{ref_table = anim, ref_value = "offset_y", mod = -4.0, timer = "REAL", not_blockable = false, delay = 0.22, ease = "quad"}
		Easing.value{ref_table = anim, ref_value = "alpha", mod = -1.0, timer = "REAL", not_blockable = false, delay = 0.22, ease = "quad"}

		M.queue_event(Tween({
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

		M.queue_event(Tween({
			mode = "delayed",
			delay = 0.24,
			blocking = true,
			func = function()
				jl.reset_anim()
				M.set_word_score_animating(false)
				M.sync_sidebar_actions()
				if WORD_GAME and WORD_GAME.HandShuffle then
					WORD_GAME.HandShuffle.try_sync()
				end
				if opts and opts.on_complete then
					opts.on_complete()
				end
				return true
			end,
		}))
	else
		jumble.advance_puzzle(wr)
		jl.reset_anim()
		M.set_word_score_animating(false)
		if opts and opts.on_complete then
			opts.on_complete()
		end
	end
end

function M.present_end_jumble_sidebar()
	if WORD_GAME and WORD_GAME.Sidebar then
		WORD_GAME.Sidebar.sync_action_buttons()
		WORD_GAME.Sidebar:refresh()
	end
end

return M
