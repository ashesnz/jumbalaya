--[[
	word_game/model/jumble_play/letter_modifier_effects.lua - Modified-letter word effects, timeline bonuses, perk merge, puzzle resets

	Core: jumbalaya_core.rules.letter_modifier_effects
	Store: none
	Presentation: none
]]

local live_game = require("word_game.model.live_game")

local perk_effects = require("word_game.model.perks.effects")
local RunMode = require("word_game.model.run.mode")
local Timeline = require("word_game.model.run.timeline")
local core = require("jumbalaya_core.rules.letter_modifier_effects")

local M = {}

local function now()
	local domain = package.loaded["word_game"]
	local engine = domain and domain.engine and domain.engine()
	if engine and engine.clock then
		return engine.clock:get_time()
	end
	return (live_game().TIMERS and live_game().TIMERS.REAL) or 0
end

local function timeline_seconds()
	return Timeline.seconds_remaining()
end

local function add_timeline_seconds(seconds)
	if RunMode.is_classic() then return end
	if not seconds or seconds <= 0 then return end
	Timeline.add_seconds(seconds)
end

function M.reset_puzzle_state(j)
	core.reset_puzzle_state(j, now())
end

function M.reset_stage_state(wr)
	core.reset_stage_state(wr)
end

function M.adjust_word_for_q(word, used_cards)
	return core.adjust_word_for_q(word, used_cards)
end

function M.compute_word_effects(word, used_cards, j, wr)
	return core.compute_word_effects(word, used_cards, j, wr, {
		now = now,
		timeline_seconds = timeline_seconds,
	})
end

function M.apply_word_effects(word, used_cards, j, wr)
	local effects = M.compute_word_effects(word, used_cards, j, wr)
	effects = perk_effects.merge_word_effects(effects, perk_effects.compute_word_effects(word, used_cards, j))
	if effects.time_bonus > 0 then
		add_timeline_seconds(effects.time_bonus)
	end
	if effects.set_next_word_multi then
		j.next_word_multi_bonus = math.max(j.next_word_multi_bonus or 0, effects.set_next_word_multi)
	end
	return effects
end

M.apply_combo_bonus = core.apply_combo_bonus
M.apply_next_word_floor = core.apply_next_word_floor
M.bank_bonus_points = core.bank_bonus_points
M.target_hit_bonus = core.target_hit_bonus
M.word_contains_letter = core.word_contains_letter

return M
