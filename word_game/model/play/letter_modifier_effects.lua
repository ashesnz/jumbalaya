--[[ word_game/model/play/letter_modifier_effects.lua - Gameplay effects for modified letter cards ]]

local deck = require("word_game.model.cards.deck")
local modifiers = deck

local M = {}

local function round_multi(value)
	return math.floor(value * 10 + 0.5) / 10
end

local function now()
	return (G.TIMERS and G.TIMERS.REAL) or 0
end

local function timeline_seconds()
	local timer = WORD_GAME and WORD_GAME.TimelineTimer
	if timer and timer.time_remaining then
		return timer.time_remaining
	end
	local j = G.GAME and G.GAME.word_round and G.GAME.word_round.jumble
	return j and j.time_left or math.huge
end

local function add_timeline_seconds(seconds)
	if not seconds or seconds <= 0 then return end
	local timer = WORD_GAME and WORD_GAME.TimelineTimer
	if timer and timer.add_time then
		timer.add_time(seconds)
		return
	end
	local j = G.GAME and G.GAME.word_round and G.GAME.word_round.jumble
	if j then
		j.time_left = (j.time_left or 0) + seconds
		if j.deadline then
			j.deadline = j.deadline + seconds
		end
	end
end

local function active_modified(cards, letter)
	return modifiers.has_modified_letter(cards, letter)
end

function M.reset_puzzle_state(j)
	if not j then return end
	j.modifier_j_used = false
	j.modifier_s_streak = 0
	j.modifier_b_pending = false
	j.puzzle_started_at = now()
	j.last_word_played_at = nil
end

function M.reset_stage_state(wr)
	if not wr then return end
	wr.modifier_x_used = false
end

function M.adjust_word_for_q(word, used_cards)
	if not word or not active_modified(used_cards, "Q") then
		return word
	end
	if word:find("QU", 1, true) then
		return word
	end
	local pos = word:find("Q", 1, true)
	if not pos then return word end
	return word:sub(1, pos) .. "U" .. word:sub(pos + 1)
end

function M.compute_word_effects(word, used_cards, j, wr)
	local effects = {
		bonus_points = 0,
		bonus_multi = 0,
		combo_bonus = 0,
		time_bonus = 0,
		set_next_word_multi = nil,
	}
	if not word or not j then return effects end

	local word_len = #word
	local prev_words = #(j.puzzle_words or {})
	local played_at = now()
	local seconds_since = played_at - (j.last_word_played_at or j.puzzle_started_at or played_at)

	if active_modified(used_cards, "A") and word:find("A", 1, true) and seconds_since <= 5 then
		effects.bonus_multi = effects.bonus_multi + 0.2
	end
	if active_modified(used_cards, "B") and word:find("B", 1, true) then
		j.modifier_b_pending = true
	end
	if active_modified(used_cards, "C") and word:find("C", 1, true) then
		effects.combo_bonus = effects.combo_bonus + 0.1
	end
	if active_modified(used_cards, "D") and word:find("D", 1, true) then
		effects.bonus_points = effects.bonus_points + 1
	end
	if active_modified(used_cards, "E") and word:find("E", 1, true) then
		effects.bonus_points = effects.bonus_points + 1
	end
	if active_modified(used_cards, "F") and word:find("F", 1, true) then
		effects.time_bonus = effects.time_bonus + 1
	end
	if active_modified(used_cards, "G") and word:find("G", 1, true) and word_len >= 5 then
		effects.bonus_multi = effects.bonus_multi + 0.5
	end
	if active_modified(used_cards, "H") and word:find("H", 1, true) and word_len >= 5 then
		effects.bonus_points = effects.bonus_points + 5
	end
	if active_modified(used_cards, "I") and word:find("I", 1, true) then
		effects.set_next_word_multi = 0.2
	end
	if active_modified(used_cards, "J") and word:find("J", 1, true) and not j.modifier_j_used then
		effects.bonus_points = effects.bonus_points + 10
		j.modifier_j_used = true
	end
	if active_modified(used_cards, "K") and word:find("K", 1, true) then
		effects.bonus_multi = effects.bonus_multi + 0.2
	end
	if active_modified(used_cards, "L") and word:find("L", 1, true) then
		local extra = math.max(0, word_len - 4)
		effects.bonus_points = effects.bonus_points + extra * 2
	end
	if active_modified(used_cards, "M") and word:find("M", 1, true) then
		effects.bonus_multi = effects.bonus_multi + 0.1
	end
	if active_modified(used_cards, "N") and word:find("N", 1, true) then
		effects.set_next_word_multi = 0.3
	end
	if active_modified(used_cards, "O") and word:find("O", 1, true) then
		local remaining = timeline_seconds()
		if remaining < 15 then
			effects.time_bonus = effects.time_bonus + 2
		end
	end
	if active_modified(used_cards, "P") and word:find("P", 1, true) and word_len >= 6 then
		effects.bonus_points = effects.bonus_points + math.floor(word_len * 0.5)
	end
	if active_modified(used_cards, "R") and word:find("R", 1, true) then
		effects.bonus_multi = effects.bonus_multi + prev_words * 0.1
	end
	if active_modified(used_cards, "S") and word:find("S", 1, true) then
		j.modifier_s_streak = (j.modifier_s_streak or 0) + 1
		effects.bonus_points = effects.bonus_points + 2 * j.modifier_s_streak
	else
		j.modifier_s_streak = 0
	end
	if active_modified(used_cards, "T") and word:find("T", 1, true) then
		effects.time_bonus = effects.time_bonus + 1
	end
	if active_modified(used_cards, "Y") and word:find("Y", 1, true) then
		local remaining = timeline_seconds()
		if remaining ~= math.huge then
			effects.bonus_points = effects.bonus_points + math.min(10, math.floor(remaining))
		end
	end
	if active_modified(used_cards, "Z") and word:find("Z", 1, true) and word_len >= 6 then
		effects.bonus_multi = effects.bonus_multi + 0.5
	end
	if active_modified(used_cards, "X") and word:find("X", 1, true) and wr and not wr.modifier_x_used then
		effects.bonus_points = effects.bonus_points + 10
		wr.modifier_x_used = true
	end

	j.last_word_played_at = played_at
	return effects
end

function M.apply_word_effects(word, used_cards, j, wr)
	local effects = M.compute_word_effects(word, used_cards, j, wr)
	if effects.time_bonus > 0 then
		add_timeline_seconds(effects.time_bonus)
	end
	if effects.set_next_word_multi then
		j.next_word_multi_bonus = math.max(j.next_word_multi_bonus or 0, effects.set_next_word_multi)
	end
	return effects
end

function M.apply_combo_bonus(base_multi, combo_bonus)
	return round_multi(base_multi + (combo_bonus or 0))
end

function M.apply_next_word_floor(base_multi, j)
	local floor_bonus = j and j.next_word_multi_bonus
	if not floor_bonus then return base_multi end
	j.next_word_multi_bonus = nil
	return round_multi(math.max(base_multi, 1.0 + floor_bonus))
end

function M.bank_bonus_points(j)
	if not j or not j.modifier_b_pending then return 0 end
	j.modifier_b_pending = false
	return 3
end

function M.target_hit_bonus(word, used_cards, old_total, new_total, target)
	if not active_modified(used_cards, "V") or not word:find("V", 1, true) then
		return 0
	end
	target = target or 20
	local old_rem = math.max(0, target - (old_total or 0))
	local new_rem = math.max(0, target - (new_total or 0))
	if old_rem > 0 and new_rem <= 0 then
		return 5
	end
	return 0
end

function M.word_contains_letter(word, letter)
	return word and letter and word:find(letter, 1, true) ~= nil
end

return M
