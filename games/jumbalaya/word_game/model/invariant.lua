--[[
	word_game/model/invariant.lua - Fail-fast assert helper for model invariant checks

	Core: none
	Store: none
	Presentation: none
]]

local M = {}

function M.check(condition, message)
	if not condition then
		error(message or "invariant violated", 2)
	end
end

return M
