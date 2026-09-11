--[[ word_game/model/perks/effects.lua - Gameplay hooks for collected perks (G glue over core) ]]

local state = require("word_game.model.run.state")
local game_access = require("word_game.model.game_access")
local round_config = require("word_game.config.gameplay.round")
local Timeline = require("word_game.model.run.timeline")
local perk_math = require("jumbalaya_core.rules.perk_math")
local core = require("jumbalaya_core.rules.perk_effects")

local M = {}

local function perk_flags()
	return {
		wide_hand = M.has("wide_hand"),
		combo_starter = M.has("combo_starter"),
		combo_master = M.has("combo_master"),
		combo_keeper = M.has("combo_keeper"),
		letter_boost = M.has("letter_boost"),
		red_rush = M.has("red_rush"),
		vowel_veil = M.has("vowel_veil"),
		long_word = M.has("long_word"),
		extra_redraw = M.has("extra_redraw"),
		time_bank = M.has("time_bank"),
		speed_demon = M.has("speed_demon"),
		time_saver = M.has("time_saver"),
		last_second = M.has("last_second"),
		risky_business = M.has("risky_business"),
		greedy = M.has("greedy"),
	}
end

function M.has(id)
	return state.has_perk(id)
end

function M.round_multi(value)
	return perk_math.round_multi(value)
end

function M.starting_puzzle_multi()
	return perk_math.starting_puzzle_multi(perk_flags())
end

function M.combo_step()
	return perk_math.combo_step(perk_flags())
end

function M.puzzle_multi_for_word_count(count)
	return perk_math.puzzle_multi_for_word_count(count, perk_flags())
end

function M.hand_size_bonus()
	return core.hand_size_bonus(perk_flags())
end

function M.timeline_seconds()
	return Timeline.seconds_remaining()
end

function M.add_timeline_seconds(seconds)
	if not seconds or seconds <= 0 then return end
	Timeline.add_seconds(seconds)
end

function M.subtract_timeline_seconds(seconds)
	if not seconds or seconds <= 0 then return end
	Timeline.add_seconds(-seconds)
end

function M.on_puzzle_start(j, wr)
	core.on_puzzle_start(j, wr, perk_flags())
end

function M.on_puzzle_bank(j)
	core.on_puzzle_bank(j, perk_flags())
	if M.has("time_bank") then
		M.add_timeline_seconds(2)
	end
end

function M.bank_total_multiplier(j)
	return core.bank_total_multiplier(j, perk_flags())
end

function M.stage_clear_bonus_points()
	return core.stage_clear_bonus_points(perk_flags(), M.timeline_seconds())
end

function M.try_award_stage_clear_bonus(j)
	return core.try_award_stage_clear_bonus(j, perk_flags(), M.timeline_seconds())
end

local function clock_now()
	local engine = WORD_GAME and WORD_GAME.engine and WORD_GAME.engine()
	if engine and engine.clock then
		return engine.clock:get_time()
	end
	return (G.TIMERS and G.TIMERS.REAL) or 0
end

function M.compute_word_effects(word, used_cards, j)
	return core.compute_word_effects(word, used_cards, j, perk_flags(), {
		now = clock_now(),
		timeline_seconds = M.timeline_seconds(),
	})
end

function M.merge_word_effects(base, perk_effects)
	return core.merge_word_effects(base, perk_effects)
end

function M.apply_point_multiplier(points, multiplier)
	return core.apply_point_multiplier(points, multiplier)
end

function M.apply_time_bank_penalty_on_word(j)
	if not j or not j.perk_time_bank_next_penalty then return end
	M.subtract_timeline_seconds(j.perk_time_bank_next_penalty)
	j.perk_time_bank_next_penalty = nil
end

function M.hold_redraw_enabled()
	return core.hold_redraw_enabled(perk_flags(), game_access.word_round())
end

function M.consume_redraw(j)
	return core.consume_redraw(j)
end

function M.redraws_remaining(j)
	return core.redraws_remaining(j)
end

return M
