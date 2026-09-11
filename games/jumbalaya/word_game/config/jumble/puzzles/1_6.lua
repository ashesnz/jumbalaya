--[[ word_game/config/jumble_puzzles/1_6.lua
     Jumble puzzle patterns for stage 1-6.
]]

local M = {}

M.PATTERNS = {
	{ center = "V", min = 3, max = 7 },
	{ suffix = "K", min = 3, max = 7 },
	{ prefix = "HO", min = 3, max = 7 },
	{ prefix = "LA", min = 3, max = 7 },
	{ prefix = "X", min = 3, max = 7 },
	{ suffix = "EN", min = 3, max = 7 },
	{ suffix = "ET", min = 3, max = 7 },
	{ suffix = "IP", min = 3, max = 7 },
	{ center = "Y", min = 3, max = 7 },
	{ prefix = "BO", min = 3, max = 7 },
	{ prefix = "CA", min = 3, max = 7 },
	{ prefix = "DO", min = 3, max = 7 },
}

return M
