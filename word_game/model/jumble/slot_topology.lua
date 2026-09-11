--[[ word_game/model/jumble/slot_topology.lua - Re-export from jumbalaya_core + runtime helpers ]]

local core = require("jumbalaya_core.jumble.slot_topology")

local M = {}
for key, value in pairs(core) do
	M[key] = value
end

function M.span_active()
	local j = WORD_GAME and WORD_GAME.Jumble and WORD_GAME.Jumble.state and WORD_GAME.Jumble.state()
	return core.span_active(j)
end

return M
