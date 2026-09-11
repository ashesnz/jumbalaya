--[[ packages/jumbalaya_core/rules/perk_effects.lua - Perk gameplay hooks (no G) ]]

local letter_tiers = require("jumbalaya_core.config.gameplay.letter_tiers")
local round_config = require("jumbalaya_core.config.gameplay.round")
local perk_math = require("jumbalaya_core.rules.perk_math")
local DictionaryCards = require("jumbalaya_core.dictionary.cards")

local M = {}

function M.hand_size_bonus(perk_flags)
	if perk_flags and perk_flags.wide_hand then return 1 end
	return 0
end

function M.on_puzzle_start(j, wr, perk_flags)
	if not j then return end
	local carry = j.perk_carry_multi or 0
	j.perk_carry_multi = nil
	j.puzzle_multi = perk_math.round_multi(perk_math.starting_puzzle_multi(perk_flags) + carry)
	j.perk_time_bank_next_penalty = nil
	j.redraws_remaining = 0
	if perk_flags and perk_flags.extra_redraw and wr and round_config.is_showdown(wr.hand_index, wr.set) then
		j.redraws_remaining = 1
	end
end

function M.on_puzzle_bank(j, perk_flags)
	if not j then return end
	if perk_flags and perk_flags.combo_keeper then
		j.perk_carry_multi = (j.puzzle_multi or 1) * 0.2
	end
	if perk_flags and perk_flags.time_bank then
		j.perk_time_bank_next_penalty = 2
	end
end

function M.bank_total_multiplier(j, perk_flags)
	if perk_flags and perk_flags.greedy and #(j.puzzle_words or {}) >= 3 then
		return 1.2
	end
	return 1.0
end

function M.stage_clear_bonus_points(perk_flags, timeline_seconds)
	if not (perk_flags and perk_flags.time_saver) then return 0 end
	local remaining = timeline_seconds or 0
	if remaining == math.huge then return 0 end
	return math.floor(remaining / 5) * 5
end

function M.try_award_stage_clear_bonus(j, perk_flags, timeline_seconds)
	if not j then return 0 end
	local bonus = M.stage_clear_bonus_points(perk_flags, timeline_seconds)
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

function M.compute_word_effects(word, used_cards, j, perk_flags, opts)
	opts = opts or {}
	local effects = {
		bonus_points = 0,
		bonus_multi = 0,
		point_multiplier = 1,
	}
	if not word then return effects end

	local word_len = #word
	if perk_flags and perk_flags.long_word and word_len >= 6 then
		effects.bonus_points = effects.bonus_points + 15
	end
	if perk_flags and perk_flags.risky_business then
		if word_len >= 6 then
			effects.bonus_multi = effects.bonus_multi + 0.5
		elseif word_len == 3 then
			effects.bonus_multi = effects.bonus_multi - 0.2
		end
	end
	if perk_flags and perk_flags.speed_demon and j and j.puzzle_started_at then
		local now = opts.now or 0
		if now - j.puzzle_started_at <= 3 then
			effects.bonus_multi = effects.bonus_multi + 0.2
		end
	end
	if perk_flags and perk_flags.last_second and (opts.timeline_seconds or math.huge) < 10 then
		effects.point_multiplier = 1.5
	end

	for _, card in ipairs(used_cards or {}) do
		local letter = card_letter(card)
		if letter then
			if perk_flags and perk_flags.red_rush and card.base and card.base.color == "red" then
				effects.bonus_points = effects.bonus_points + 1
			end
			if perk_flags and perk_flags.vowel_veil and DictionaryCards.is_vowel_letter(letter) then
				effects.bonus_points = effects.bonus_points + 2
			end
			if perk_flags and perk_flags.letter_boost and letter_tiers.value_for(letter) >= 4 then
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

function M.consume_redraw(j)
	if not j or (j.redraws_remaining or 0) <= 0 then return false end
	j.redraws_remaining = j.redraws_remaining - 1
	return true
end

function M.redraws_remaining(j)
	return j and j.redraws_remaining or 0
end

function M.hold_redraw_enabled(perk_flags, wr)
	if not (perk_flags and perk_flags.extra_redraw) then return false end
	return wr and round_config.is_showdown(wr.hand_index, wr.set) or false
end

return M
