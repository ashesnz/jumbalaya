--[[ word_game/config/jumble_puzzles/1_2.lua
     Jumble puzzle patterns for stage 1-2.
]]

local M = {}

M.PATTERNS = {
	{ center = "L", pin_index = 2, min = 3, max = 7 },
	{ center = "P", pin_index = 3, min = 3, max = 7 },
	{ center = "D", min = 3, max = 7 },
	{ center = "S", min = 3, max = 7 },
	{ center = "A", min = 3, max = 7 },
	{ center = "R", min = 3, max = 7 },
	{ suffix = "I", min = 3, max = 7 },
	{ suffix = "A", min = 3, max = 7 },
	{ prefix = "W", min = 3, max = 7 },
	{ suffix = "X", min = 3, max = 7 },
	{ suffix = "C", min = 3, max = 7 },
	{ prefix = "I", min = 3, max = 7 },
	{ prefix = "Y", min = 3, max = 7 },
    { pattern = "_D_E___", min = 4, max = 7 },
}

return M
