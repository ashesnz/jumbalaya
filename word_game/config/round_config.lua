--[[ word_game/config/round_config.lua - Set / Hand targets and play limits ]]

local M = {
	DISCARDS_PER_HAND = 3,
	TIMELINE_SECONDS = 60,
	SETS_TO_WIN = 8,
	MIN_WORD_LEN = 3,
	MAX_WORD_LEN = 7,

	-- Set 1 runs nine hands (1-1 … 1-9); later sets use three hands each.
	HANDS_IN_SET = {
		[1] = 9,
	},

	HAND_CYCLE = { "Standard", "Standard", "Showdown" },

	HAND_TARGETS = {
		[1] = { 200, 2, 2, 150, 20, 30, 40, 50, 60 },
		[2] = { 400, 560, 700 },
		[3] = { 800, 1120, 1400 },
		[4] = { 1600, 2240, 2800 },
		[5] = { 3200, 4480, 5600 },
		[6] = { 6400, 8960, 11200 },
		[7] = { 12800, 17920, 22400 },
		[8] = { 25600, 35840, 44800 },
	},

	-- Stage odometer hand that plays the Milo / Aleisha boss intro (1-3).
	STAGE3_CINEMATIC = { set = 1, hand = 3 },
	-- Set 1 hands where boss-word gold cards sit in the left gutter (1-4 … 1-6).
	BONUS_STACK_HAND_FIRST = 4,
	BONUS_STACK_HAND_LAST = 6,
	-- Set 1 hand 7: Milo + Aleisha stay left, boss drops, Marco joins.
	MARCO_CINEMATIC = { set = 1, hand = 7 },
}

function M.hands_in_set(set)
	set = set or 1
	return M.HANDS_IN_SET[set] or 3
end

function M.hand_target(set, hand_index)
	set = set or 1
	hand_index = hand_index or 1
	local row = M.HAND_TARGETS[set]
	if not row then
		local last = #M.HAND_TARGETS
		local base = M.HAND_TARGETS[last] or M.HAND_TARGETS[1]
		local mul = 2 ^ math.max(0, set - last)
		row = {
			math.floor((base[1] or 0) * mul + 0.5),
			math.floor((base[2] or 0) * mul + 0.5),
			math.floor((base[3] or 0) * mul + 0.5),
		}
	end
	return row[hand_index] or row[1]
end

function M.hand_name(hand_index, set)
	set = set or 1
	if set == 1 then
		if hand_index == 3 then return "Showdown" end
		if hand_index == 7 then return "Showdown" end
		if hand_index == 9 then return "Showdown" end
		return "Standard"
	end
	return M.HAND_CYCLE[hand_index] or "Standard"
end

function M.is_showdown(hand_index, set)
	return M.hand_name(hand_index, set) == "Showdown"
end

function M.is_boss_word_hand(set, hand_index)
	return set == 1 and hand_index == 3
end

function M.is_bonus_stack_hand(set, hand_index)
	set = set or 1
	hand_index = hand_index or 1
	return set == 1
		and hand_index >= M.BONUS_STACK_HAND_FIRST
		and hand_index <= M.BONUS_STACK_HAND_LAST
end

function M.is_token_reward_hand(set, hand_index)
	return set == 1 and hand_index == 1
end

function M.is_final_hand(set, hand_index)
	set = set or 1
	hand_index = hand_index or 1
	return set >= M.SETS_TO_WIN and hand_index >= M.hands_in_set(set)
end

function M.is_stage3_cinematic_hand(set, hand_index)
	local row = M.STAGE3_CINEMATIC
	return row and set == row.set and hand_index == row.hand
end

function M.is_marco_cinematic_hand(set, hand_index)
	local row = M.MARCO_CINEMATIC
	return row and set == row.set and hand_index == row.hand
end

function M.is_cinematic_hand(set, hand_index)
	return M.is_stage3_cinematic_hand(set, hand_index) or M.is_marco_cinematic_hand(set, hand_index)
end

function M.cinematic_id(set, hand_index)
	if M.is_stage3_cinematic_hand(set, hand_index) then return "1-3" end
	if M.is_marco_cinematic_hand(set, hand_index) then return "1-7" end
	return nil
end

function M.stage_label(set, hand_index)
	return string.format("%d-%d", set or 1, hand_index or 1)
end

-- Aleisha is in the party from 1-3 onward.
function M.aleisha_has_joined(set, hand_index)
	set = set or 1
	hand_index = hand_index or 1
	if set > 1 then return true end
	return hand_index >= 3
end

-- Marco is in the party from 1-7 onward.
function M.marco_has_joined(set, hand_index)
	set = set or 1
	hand_index = hand_index or 1
	if set > 1 then return true end
	return hand_index >= 7
end

return M
