--[[
	word_game/model/jumble/slot_topology.lua - Re-exports core slot topology plus span_active() from live jumble state

	Core: jumbalaya_core.jumble.slot_topology
	Store: none
	Presentation: none
]]

local core = require("jumbalaya_core.jumble.slot_topology")

local function jumble_module()
	return package.loaded["word_game.model.jumble"]
end

local M = {}
for key, value in pairs(core) do
	M[key] = value
end

function M.span_active()
	local jumble = jumble_module()
	local j = jumble and jumble.state()
	return core.span_active(j)
end

return M
