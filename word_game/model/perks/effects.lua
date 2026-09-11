--[[ word_game/model/perks/effects.lua - Gameplay hooks for collected perks ]]

local state = require("word_game.model.run.state")
local round_config = require("word_game.config.gameplay.round")
local Dictionary = require("dictionary")
local Timeline = require("word_game.model.run.timeline")
local perk_math = require("jumbalaya_core.rules.perk_math")

local M = {}

local LETTER_VALUE = {}
local TIERS = {
	{ value = 1, letters = { "A", "E", "I", "O", "U", "L", "N", "S", "T", "R" } },
	{ value = 2, letters = { "D", "G" } },
	{ value = 3, letters = { "B", "C", "M", "P" } },
	{ value = 4, letters = { "F", "H", "V", "W", "Y" } },
	{ value = 5, letters = { "K" } },
	{ value = 8, letters = { "J", "X" } },
	{ value = 10, letters = { "Q", "Z" } },
}
for _, tier in ipairs(TIERS) do
	for _, letter in ipairs(tier.letters) do
		LETTER_VALUE[letter] = tier.value
	end
end

function M.has(id)
	return state.has_perk(id)
end

local function perk_flags()
	return {
		combo_starter = M.has("combo_starter"),
		combo_master = M.has("combo_master"),
	}
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
	if M.has("wide_hand") then return 1 end
	return 0
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
	if not j then return end
	local carry = j.perk_carry_multi or 0
	j.perk_carry_multi = nil
	j.puzzle_multi = M.round_multi(M.starting_puzzle_multi() + carry)
	j.perk_time_bank_next_penalty = nil
	j.redraws_remaining = 0
	if M.has("extra_redraw") and wr and round_config.is_showdown(wr.hand_index, wr.set) then
		j.redraws_remaining = 1
	end
end

function M.on_puzzle_bank(j)
	if not j then return end
	if M.has("combo_keeper") then
		j.perk_carry_multi = (j.puzzle_multi or 1) * 0.2
	end
	if M.has("time_bank") then
		M.add_timeline_seconds(2)
		j.perk_time_bank_next_penalty = 2
	end
end

function M.bank_total_multiplier(j)
	if M.has("greedy") and #(j.puzzle_words or {}) >= 3 then
		return 1.2
	end
	return 1.0
end

function M.stage_clear_bonus_points()
	if not M.has("time_saver") then return 0 end
	local remaining = M.timeline_seconds()
	if remaining == math.huge then return 0 end
	return math.floor(remaining / 5) * 5
end

function M.try_award_stage_clear_bonus(j)
	if not j then return 0 end
	local bonus = M.stage_clear_bonus_points()
	if bonus <= 0 then return 0 end
	j.total_score = (j.total_score or 0) + bonus
	return bonus
end

local function card_letter(card)
	if not card then return nil end
	if card.base and card.base.letter then return card.base.letter end
	local raw = card.config and card.config.card
	return raw and raw.letter
end

function M.compute_word_effects(word, used_cards, j)
	local effects = {
		bonus_points = 0,
		bonus_multi = 0,
		point_multiplier = 1,
	}
	if not word then return effects end

	local word_len = #word
	if M.has("long_word") and word_len >= 6 then
		effects.bonus_points = effects.bonus_points + 15
	end
	if M.has("risky_business") then
		if word_len >= 6 then
			effects.bonus_multi = effects.bonus_multi + 0.5
		elseif word_len == 3 then
			effects.bonus_multi = effects.bonus_multi - 0.2
		end
	end
	if M.has("speed_demon") and j and j.puzzle_started_at then
		local now = (G.TIMERS and G.TIMERS.REAL) or 0
		if now - j.puzzle_started_at <= 3 then
			effects.bonus_multi = effects.bonus_multi + 0.2
		end
	end
	if M.has("last_second") and M.timeline_seconds() < 10 then
		effects.point_multiplier = 1.5
	end

	for _, card in ipairs(used_cards or {}) do
		local letter = card_letter(card)
		if letter then
			if M.has("red_rush") and card.base and card.base.color == "red" then
				effects.bonus_points = effects.bonus_points + 1
			end
			if M.has("vowel_veil") and Dictionary.is_vowel_letter(letter) then
				effects.bonus_points = effects.bonus_points + 2
			end
			if M.has("letter_boost") and (LETTER_VALUE[letter] or 0) >= 4 then
				effects.bonus_points = effects.bonus_points + 2
			end
		end
	end

	return effects
end

function M.merge_word_effects(base, perk_effects)
	if not perk_effects then return base end
	base.bonus_points = (base.bonus_points or 0) + (perk_effects.bonus_points or 0)
	base.bonus_multi = (base.bonus_multi or 0) + (perk_effects.bonus_multi or 0)
	if perk_effects.point_multiplier and perk_effects.point_multiplier > (base.point_multiplier or 1) then
		base.point_multiplier = perk_effects.point_multiplier
	end
	return base
end

function M.apply_point_multiplier(points, multiplier)
	multiplier = multiplier or 1
	if multiplier <= 1 then return points end
	return math.floor(points * multiplier)
end

function M.apply_time_bank_penalty_on_word(j)
	if not j or not j.perk_time_bank_next_penalty then return end
	M.subtract_timeline_seconds(j.perk_time_bank_next_penalty)
	j.perk_time_bank_next_penalty = nil
end

function M.hold_redraw_enabled()
	if not M.has("extra_redraw") then return false end
	local wr = G.GAME and G.GAME.word_round
	return wr and round_config.is_showdown(wr.hand_index, wr.set) or false
end

function M.consume_redraw(j)
	if not j or (j.redraws_remaining or 0) <= 0 then return false end
	j.redraws_remaining = j.redraws_remaining - 1
	return true
end

function M.redraws_remaining(j)
	return j and j.redraws_remaining or 0
end

return M
