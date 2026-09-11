--[[ packages/jumbalaya_core/round/init.lua - Set/hand progression (no G) ]]

local round_config = require("jumbalaya_core.config.gameplay.round")

local M = {}

function M.new_word_round(set, hand_index)
	set = set or 1
	hand_index = hand_index or 1
	return {
		set = set,
		hand_index = hand_index,
		target = round_config.hand_target(set, hand_index),
		hand_name = round_config.hand_name(hand_index, set),
		played_words = {},
	}
end

function M.run_reset_fields()
	return {
		voucher_discards_used = 0,
		discard_bin_count = 0,
	}
end

function M.is_word_played(wr, word)
	if not word or word == "" then return false end
	word = string.upper(word)
	return wr and wr.played_words and wr.played_words[word] or false
end

function M.record_word_play(wr, word)
	if not word or word == "" or not wr then return end
	word = string.upper(word)
	wr.played_words = wr.played_words or {}
	wr.played_words[word] = true
end

function M.is_final_hand(wr)
	if not wr then return false end
	return wr.set >= round_config.SETS_TO_WIN
		and wr.hand_index >= round_config.hands_in_set(wr.set)
end

--- Returns action name and the next hand coordinates (set, hand_index).
--- Actions: "next", "next_set", "win", "none"
function M.advance_hand(wr)
	if not wr then return "none", nil, nil end

	if wr.hand_index >= round_config.hands_in_set(wr.set) then
		if wr.set >= round_config.SETS_TO_WIN then
			return "win", wr.set, wr.hand_index
		end
		return "next_set", wr.set + 1, 1
	end

	return "next", wr.set, wr.hand_index + 1
end

function M.start_hand_coords(set, hand_index)
	return M.new_word_round(set, hand_index)
end

return M
