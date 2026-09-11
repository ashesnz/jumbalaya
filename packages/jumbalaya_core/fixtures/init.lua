--[[ packages/jumbalaya_core/fixtures/init.lua - Test fixtures for headless core tests ]]

local default_state = require("jumbalaya_core.store.default_state")

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

return M
