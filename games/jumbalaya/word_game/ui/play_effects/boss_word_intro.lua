--[[
	word_game/ui/play_effects/boss_word_intro.lua — Boss-word intro: stage banner + 3-2-1, then reveal.
	Inputs: word_round, facade jumble/deck, TimelineTimer, ScoreBanner, effects host.
	Outputs: present_boss_word(wr, on_complete); countdown via word_feedback.show_boss_countdown.
]]

local play_sfx = require("jumbalaya-engine.sound.sound").play_sfx
local game = require("word_game.ui.util.game_runtime").game
local Scheduler = require("jumbalaya-engine.effects.timeline_scheduler")

local facade = require("word_game.ui.facade")

local M = {}

local definition
local word_feedback
local round_config
local effects_host

function M.bind(deps)
	definition = deps.definition
	word_feedback = deps.word_feedback
	round_config = deps.round_config
	effects_host = deps.effects
end

local function effects()
	return effects_host and effects_host() or nil
end

local function game_access()
	return facade.game_access()
end

local function live_word_round()
	return game_access().word_round()
end

local function clear_boss_staging()
	game_access().dispatch({ type = "JUMBLE_CLEAR_BOSS_STAGING" })
end

local function clear_locked_hand_layout()
	game_access().dispatch({ type = "JUMBLE_SET_LOCKED_HAND_LAYOUT" })
end

local function clear_hand_clear_blockers()
	if WORD_GAME_UI.HandClearFocus and WORD_GAME_UI.HandClearFocus.end_focus then
		WORD_GAME_UI.HandClearFocus.end_focus()
	end
	if WORD_GAME_UI.TokenReward and WORD_GAME_UI.TokenReward.reset then
		WORD_GAME_UI.TokenReward.reset()
	end
end

local function run_countdown(on_complete)
	local intro = definition.BOSS_INTRO
	local steps = intro.steps
	if not steps or #steps == 0 then
		if on_complete then on_complete() end
		return
	end

	local first = steps[1]
	word_feedback.show_boss_countdown(first.text, first.hold)
	if play_sfx then
		play_sfx("timpani", 0.9, 0.7)
	end

	local delay = first.hold
	for index = 2, #steps do
		local step = steps[index]
		Scheduler.add{
			mode = "delayed",
			delay = delay,
			blocking = false,
			func = function()
				word_feedback.show_boss_countdown(step.text, step.hold)
				if play_sfx then
					if index == #steps then
						play_sfx("timpani", 0.95, 0.85)
					else
						play_sfx("card_tick", 0.9, 0.7)
					end
				end
				return true
			end,
		}
		delay = delay + step.hold
	end
	Scheduler.add{
		mode = "delayed",
		delay = delay + (intro.countdown_tail or 0.12),
		blocking = false,
		func = function()
			if on_complete then on_complete() end
			return true
		end,
	}
end

function M.present_boss_word(_wr, on_complete)
	local jumble = facade.jumble()
	local deck = facade.deck()
	if not _wr or not jumble or not deck then
		if on_complete then on_complete() end
		return
	end

	clear_hand_clear_blockers()

	if game().dealt_letters then
		clear_locked_hand_layout()
	end

	definition.set_word_score_animating(true)
	if WORD_GAME_UI.ScoreBanner and WORD_GAME_UI.ScoreBanner.hide_points_to_get_display then
		WORD_GAME_UI.ScoreBanner.hide_points_to_get_display()
	end
	if WORD_GAME_UI.ScoreBanner and WORD_GAME_UI.ScoreBanner.set_banner_mode then
		WORD_GAME_UI.ScoreBanner.set_banner_mode("boss_word")
	end

	local tt = WORD_GAME_UI.TimelineTimer
	if tt and tt.hide_slider then
		tt.hide_slider(0)
	end

	local deal_done = false
	local countdown_done = false

	local function reveal_boss_phase()
		if tt and tt.arm_boss_countdown then
			tt.arm_boss_countdown(round_config.TIMELINE_SECONDS)
		end
		if tt and tt.reveal_countdown_timer then
			tt.reveal_countdown_timer(0)
		end
		local revealed = jumble.reveal_boss_puzzle()
		if not revealed then
			definition.set_word_score_animating(false)
			clear_boss_staging()
			if on_complete then on_complete() end
			return
		end
		if WORD_GAME_UI.Layout and WORD_GAME_UI.Layout.refresh_placement_layout then
			WORD_GAME_UI.Layout.refresh_placement_layout()
		elseif game().pattern_row and game().pattern_row.apply_screen_position then
			game().pattern_row:apply_screen_position()
		end
		if WORD_GAME_UI.Sidebar and WORD_GAME_UI.Sidebar.sync_visibility then
			WORD_GAME_UI.Sidebar.sync_visibility()
		end
		if WORD_GAME_UI.TableControls then
			WORD_GAME_UI.TableControls.sync_position()
		end
		local fx = effects()
		if fx and fx.request_layout_refresh then
			fx.request_layout_refresh()
		end
		definition.set_word_score_animating(false)
		definition.sync_hand_controls()
		if play_sfx then
			play_sfx("coin2", 0.95, 0.85)
		end
		if on_complete then on_complete() end
	end

	local function try_reveal_boss_phase()
		if not deal_done or not countdown_done then return end
		reveal_boss_phase()
	end

	run_countdown(function()
		countdown_done = true
		try_reveal_boss_phase()
	end)

	local function deal_boss_hand()
		local wr = live_word_round()
		local j = wr and wr.jumble
		if not j or not j.pending_boss then
			definition.set_word_score_animating(false)
			clear_boss_staging()
			if on_complete then on_complete() end
			return
		end
		local puzzle = j.pending_boss
		local letters = jumble.boss_hand_letters(puzzle.boss_word, puzzle.pattern)
		deck.deal_boss_hand(letters, function()
			definition.sync_hand_after_deal()
			word_feedback.lock_hand_layout()
			deal_done = true
			try_reveal_boss_phase()
		end, { fast = true, instant_deal = true })
	end

	if not jumble.prepare_boss_word() then
		definition.set_word_score_animating(false)
		clear_boss_staging()
		if on_complete then on_complete() end
		return
	end
	if WORD_GAME_UI.Sidebar and WORD_GAME_UI.Sidebar.sync_visibility then
		WORD_GAME_UI.Sidebar.sync_visibility()
	end

	deck.return_hand_to_deck(function()
		deal_boss_hand()
	end, { instant = true })
end

return M
