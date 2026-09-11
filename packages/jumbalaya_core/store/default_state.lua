--[[ packages/jumbalaya_core/store/default_state.lua - Default GameRunState snapshot ]]

local M = {}

function M.new_word_round(overrides)
	local wr = {
		set = 1,
		hand_index = 1,
		target = 25,
		played_words = {},
		mode = "jumble",
	}
	if overrides then
		for key, value in pairs(overrides) do
			wr[key] = value
		end
	end
	return wr
end

function M.new_jumble_state(overrides)
	local j = {
		total_score = 0,
		puzzle_index = 1,
		solved = false,
		puzzle_points = 0,
		puzzle_multi = 1.0,
		puzzle_words = {},
		slots = {},
	}
	if overrides then
		for key, value in pairs(overrides) do
			j[key] = value
		end
	end
	return j
end

function M.new(overrides)
	local state = {
		points = 0,
		round = 1,
		word_round = M.new_word_round(),
		piles = {
			hand = {},
			draw = {},
			pattern = {},
			bonus = {},
			discard = {},
		},
	}
	if overrides then
		for key, value in pairs(overrides) do
			state[key] = value
		end
	end
	return state
end

return M
