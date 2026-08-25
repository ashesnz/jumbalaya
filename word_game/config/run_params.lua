--[[ word_game/config/run_params.lua - per-run starting parameters ]]

local M = {}

--- Values consumed when a fresh run's state table is built.
function M.get()
	return {
		hand_size = 8,
		discards = 1,
		hands = 1,
		usable_slots = 2,
	}
end

return M
