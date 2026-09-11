--[[ word_game/model/invariant.lua - Fail-fast checks for model invariants ]]

local M = {}

function M.check(condition, message)
	if not condition then
		error(message or "invariant violated", 2)
	end
end

return M
