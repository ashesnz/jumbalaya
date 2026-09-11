--[[
	bridge/runtime.lua - Phase 7 runtime service accessors (store + engine).
]]

local M = {}

local function word_game()
	return package.loaded["word_game"]
end

function M.store()
	local wg = word_game()
	if wg and wg.store then
		return wg.store()
	end
	return nil
end

function M.engine()
	local wg = word_game()
	if wg and wg.engine then
		return wg.engine()
	end
	return nil
end

return M
