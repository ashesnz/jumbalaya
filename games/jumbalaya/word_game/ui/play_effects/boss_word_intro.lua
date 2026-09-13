--[[
	word_game/ui/play_effects/boss_word_intro.lua — Boss-word 3-2-1 intro and hand staging.
	Inputs: word_round, facade jumble/deck, TimelineTimer, ScoreBanner, effects host.
	Outputs: present_boss_word(wr, on_complete); countdown via word_feedback.show_boss_countdown.
]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

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

local function has_event_manager()
	return runtime().TIMELINE and runtime().TIMELINE.enqueue
end

function M.present_boss_word(_wr, on_complete)
	local jumble = facade.jumble()
	local deck = facade.deck()
	if not _wr or not jumble or not deck then
		if on_complete then on_complete() end
		return
	end

	if runtime().dealt_letters then
		clear_locked_hand_layout()
	end

	definition.set_word_score_animating(true)
	if WORD_GAME_UI.ScoreBanner and WORD_GAME_UI.ScoreBanner.hide_points_to_get_display then
		WORD_GAME_UI.ScoreBanner.hide_points_to_get_display()
	end
	if WORD_GAME_UI.TimelineTimer and WORD_GAME_UI.TimelineTimer.pause then
		WORD_GAME_UI.TimelineTimer.pause()
	end

	local function finish_intro()
		local tt = WORD_GAME_UI.TimelineTimer
		if tt and tt.arm_boss_countdown then
			tt.arm_boss_countdown(round_config.TIMELINE_SECONDS)
		end
		if tt and tt.reveal_countdown_timer then
			local reveal_dur = has_event_manager() and definition.BOSS_INTRO.timer_reveal_duration or 0
			tt.reveal_countdown_timer(reveal_dur)
		end
		if WORD_GAME_UI.ScoreBanner and WORD_GAME_UI.ScoreBanner.set_banner_mode then
			WORD_GAME_UI.ScoreBanner.set_banner_mode("boss_word", "BOSS WORD")
		end
		if WORD_GAME_UI.BossWordAnnounce then
			if WORD_GAME_UI.BossWordAnnounce.play_boss then
				WORD_GAME_UI.BossWordAnnounce.play_boss("BOSS WORD")
			end
			if WORD_GAME_UI.BossWordAnnounce.play_theme then
				WORD_GAME_UI.BossWordAnnounce.play_theme("Garden Theme")
			end
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
		elseif runtime().pattern_row and runtime().pattern_row.apply_screen_position then
			runtime().pattern_row:apply_screen_position()
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

	local function run_countdown(done)
		local steps = definition.BOSS_INTRO.steps
		local fx = effects()
		local function queue_step(index)
			if index > #steps then
				if fx and fx.queue_event then
					fx.queue_event(Tween({
						mode = "delayed",
						delay = 0.12,
						blocking = true,
						func = function()
							if done then done() end
							return true
						end,
					}))
				elseif done then
					done()
				end
				return
			end
			local step = steps[index]
			if not (fx and fx.queue_event) then
				queue_step(index + 1)
				return
			end
			fx.queue_event(Tween({
				mode = "delayed",
				delay = 0,
				blocking = true,
				func = function()
					word_feedback.show_boss_countdown(step.text, step.hold)
					if play_sfx then
						if index == 1 then
							play_sfx("timpani", 0.9, 0.7)
						else
							play_sfx("card_tick", 0.9, 0.7)
						end
					end
					fx.queue_event(Tween({
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

	local hide_done = false
	local deal_done = false
	local started = false

	local function start_if_ready()
		if started or not hide_done or not deal_done then return end
		started = true
		run_countdown(finish_intro)
	end

	local hide_dur = has_event_manager() and definition.BOSS_INTRO.hide_duration or 0
	if WORD_GAME_UI.TimelineTimer and WORD_GAME_UI.TimelineTimer.hide_slider then
		WORD_GAME_UI.TimelineTimer.hide_slider(hide_dur, function()
			hide_done = true
			start_if_ready()
		end)
	else
		hide_done = true
	end

	local function after_boss_deal()
		deal_done = true
		start_if_ready()
	end

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
			after_boss_deal()
		end, { fast = true })
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
