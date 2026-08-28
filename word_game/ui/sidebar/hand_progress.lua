--[[ word_game/ui/sidebar/hand_progress.lua - Hand progress odometer and roll transitions ]]

local round_config = require("word_game.config.round_config")
local Odometer = require("word_game.ui.odometer")

local M = {}

local hand_progress_meter
local pending_hand_roll

local function set_number()
	local wr = G.GAME and G.GAME.word_round
	return wr and wr.set or 1
end

local function hand_number()
	local wr = G.GAME and G.GAME.word_round
	return wr and wr.hand_index or 1
end

local function next_set_and_hand(set, hand)
	local hands = round_config.hands_in_set(set)
	if hand >= hands then
		if set >= round_config.SETS_TO_WIN then
			return nil
		end
		return set + 1, 1
	end
	return set, hand + 1
end

local function apply_pending_hand_roll()
	local pending = pending_hand_roll
	if not pending or not hand_progress_meter then return end
	hand_progress_meter.left_count = pending.from_set
	hand_progress_meter.right_count = pending.from_hand
	hand_progress_meter:start_pair_roll(
		pending.from_set,
		pending.from_hand,
		pending.to_set,
		pending.to_hand
	)
	if hand_progress_meter.pulse then
		hand_progress_meter:pulse(0.35, 0.2)
	end
	pending_hand_roll = nil
end

function M.roll_plays(from, to)
end

function M.roll_to_next_hand()
	local from_set = set_number()
	local from_hand = hand_number()
	local to_set, to_hand = next_set_and_hand(from_set, from_hand)
	if not to_set then return end
	pending_hand_roll = {
		from_set = from_set,
		from_hand = from_hand,
		to_set = to_set,
		to_hand = to_hand,
	}
	if hand_progress_meter then
		apply_pending_hand_roll()
	end
end

function M.odometer_node(box_w)
	return { n = G.UI.OBJECT, config = {
		id = "hand_progress_odometer",
		object = (function()
			hand_progress_meter = Odometer({
				label = "Set / Hand",
				label_on_top = true,
				pair = true,
				left = set_number(),
				right = hand_number(),
				colour = G.C.GOLD,
				subtitle_fn = function(hand)
					local set = set_number()
					if round_config.is_showdown(hand, set)
						and not round_config.is_stage3_cinematic_hand(set, hand)
						and not round_config.is_marco_cinematic_hand(set, hand) then
						return "Boss Battle"
					end
				end,
				subtitle_colour = G.C.RED,
				w = box_w * 0.82,
				h = 0.82,
			})
			apply_pending_hand_roll()
			return hand_progress_meter
		end)(),
	}}
end

function M.reset()
	hand_progress_meter = nil
end

return M
