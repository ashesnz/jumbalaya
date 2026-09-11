--[[ packages/jumbalaya_core/fixtures/init.lua - Test fixtures for headless core tests ]]

local default_state = require("jumbalaya_core.store.default_state")
local run_state = require("jumbalaya_core.store.run_state")

local M = {}

function M.jumble_word_round(opts)
	opts = opts or {}
	local jumble = default_state.new_jumble_state(opts.jumble)
	local wr = default_state.new_word_round({
		mode = "jumble",
		jumble = jumble,
		target = opts.target,
		set = opts.set,
		hand_index = opts.hand_index,
	})
	if opts.puzzle then
		jumble.puzzle = opts.puzzle
	end
	if opts.slots then
		jumble.slots = opts.slots
	end
	return wr
end

function M.run_state(opts)
	return run_state.new(opts)
end

function M.letter_card(letter, opts)
	opts = opts or {}
	return {
		ability = {
			letter = letter,
			letter_color = opts.color or "black",
			modified = opts.modified,
		},
		base = opts.base,
		bonus_card = opts.bonus_card,
	}
end

function M.seeded_rng(seed)
	seed = seed or 1
	return function(key, min, max)
		seed = (seed * 1103515245 + 12345 + (key and #key or 0)) % 2147483648
		if max <= min then return min end
		return min + (seed % (max - min + 1))
	end
end

return M
