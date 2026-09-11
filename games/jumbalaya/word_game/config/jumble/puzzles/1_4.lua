--[[ word_game/config/jumble_puzzles/1_4.lua
     Jumble puzzle patterns for stage 1-4.
]]

local M = {}

M.PATTERNS = {
	{ prefix = "B", min = 3, max = 7 },
	{ suffix = "E", min = 3, max = 7 },
	{ center = "T", min = 3, max = 7 },
	{ prefix = "M", min = 3, max = 7 },
	{ suffix = "Y", min = 3, max = 7 },
	{ prefix = "F", min = 3, max = 7 },
	{ suffix = "L", min = 3, max = 7 },
	{ center = "R", min = 3, max = 7 },
}

return M
