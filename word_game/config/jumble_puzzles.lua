--[[ word_game/config/jumble_puzzles.lua
     Router and loader for stage-specific jumble puzzle patterns.
     Stage pattern definitions are broken up into:
       jumble_puzzles/1_1.lua through jumble_puzzles/8_3.lua
]]

local M = {}

function M.get_stage(set, hand_index)
	set = set or 1
	hand_index = hand_index or 1
	local name = string.format("word_game.config.jumble_puzzles.%d_%d", set, hand_index)
	local ok, mod = pcall(require, name)
	if ok and mod and (mod.PATTERNS or mod.PUZZLES) then
		return mod
	end
	return require("word_game.config.jumble_puzzles.1_1")
end

-- Default export forwards to stage 1-1 for backwards compatibility
local stage_1_1 = require("word_game.config.jumble_puzzles.1_1")
M.PATTERNS = stage_1_1.PATTERNS

return M
