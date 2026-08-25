--[[ word_game/config/round_config.lua - Set / Hand targets and play limits ]]

local M = {
	PLAYS_PER_HAND = 6,
	HAND_SIZE = 7,
	REDRAWS_PER_HAND = 3,
	SETS_TO_WIN = 8,
	MIN_WORD_LEN = 3,
	MAX_WORD_LEN = 7,

	-- GDD length table: flat AP bonus and base Boost
	LENGTH = {
		[3] = { ap = 10, boost = 1 },
		[4] = { ap = 20, boost = 2 },
		[5] = { ap = 35, boost = 3 },
		[6] = { ap = 50, boost = 5 },
		[7] = { ap = 80, boost = 8, sweep_ap = 50 },
	},

	SWEEP_BOOST = 8,
	GRAND_SLAM_BOOST = 12,

	HAND_CYCLE = { "Standard", "Standard", "Showdown" },

	HAND_TARGETS = {
		[1] = { 2, 2, 2 },
		[2] = { 100, 140, 175 },
		[3] = { 200, 280, 350 },
		[4] = { 400, 560, 700 },
		[5] = { 800, 1120, 1400 },
		[6] = { 1600, 2240, 2800 },
		[7] = { 3200, 4480, 5600 },
		[8] = { 6400, 8960, 11200 },
	},

	-- Stage odometer hand that plays the Milo / Aleisha boss intro (e.g. 1-3).
	STAGE3_CINEMATIC = { set = 1, hand = 3 },
	-- Set 2 Showdown: Milo + Aleisha stay left, boss drops, Marco joins.
	MARCO_CINEMATIC = { set = 2, hand = 3 },
}

function M.length_bonus(len)
	return M.LENGTH[len] or M.LENGTH[M.MAX_WORD_LEN]
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

function M.hand_name(hand_index)
	return M.HAND_CYCLE[hand_index] or "Standard"
end

function M.is_showdown(hand_index)
	return M.hand_name(hand_index) == "Showdown"
end

-- Sets 1–3 showdown hands: perk pick, except stage 1-3's boss word.
function M.is_early_showdown(set, hand_index)
	return (set or 1) <= 3 and M.is_showdown(hand_index)
end

function M.is_perk_hand(set, hand_index)
	return M.is_early_showdown(set, hand_index)
end

-- The perk marketplace opens after the showdown hand is cleared.
function M.is_perk_market_after(set, hand_index)
	return M.is_early_showdown(set, hand_index) and not (set == 1 and hand_index == 3)
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
	if M.is_marco_cinematic_hand(set, hand_index) then return "2-3" end
	return nil
end

-- Aleisha is in the party from 1-3 onward (all later sets included).
function M.aleisha_has_joined(set, hand_index)
	set = set or 1
	hand_index = hand_index or 1
	if set > 1 then return true end
	return set == 1 and hand_index >= 3
end

-- Marco is in the party from 2-3 onward.
function M.marco_has_joined(set, hand_index)
	set = set or 1
	hand_index = hand_index or 1
	if set > 2 then return true end
	return set == 2 and hand_index >= 3
end

return M
