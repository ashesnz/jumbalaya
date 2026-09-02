--[[ word_game/config/run_params.lua - per-run starting parameters ]]

local hand_size = require("word_game.config.hand_size")

local M = {}

--- Values consumed when a fresh run's state table is built.
function M.get()
	return {
		hand_size = hand_size.get(),
		usable_slots = 2,
	}
end

return M
