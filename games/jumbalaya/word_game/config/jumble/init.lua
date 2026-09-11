--[[
	word_game/config/jumble/init.lua - Router for stage-specific jumble puzzle patterns.

	Stage tables live in `jumble/puzzles/{set}_{hand}.lua` (e.g. 1_1 … 8_3).
]]

local M = {}

function M.get_stage(set, hand_index)
	set = set or 1
	hand_index = hand_index or 1
	local name = string.format("word_game.config.jumble.puzzles.%d_%d", set, hand_index)
	local ok, mod = pcall(require, name)
	if ok and mod and (mod.PATTERNS or mod.PUZZLES) then
		return mod
	end
	return require("word_game.config.jumble.puzzles.1_1")
end

local stage_1_1 = require("word_game.config.jumble.puzzles.1_1")
M.PATTERNS = stage_1_1.PATTERNS

return M
