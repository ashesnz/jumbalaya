--[[ word_game/config/gameplay/run_params.lua - Per-run starting parameters ]]

local hand_size = require("word_game.model.hand_size")

local M = {}

--- Values consumed when a fresh run's state table is built.
function M.get()
	return {
		hand_size = hand_size.get(),
	}
end

return M
