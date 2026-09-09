--[[ word_game/config/jumble_puzzles/1_8.lua
     Jumble puzzle patterns for stage 1-8.
]]

local M = {}

M.PATTERNS = {
	{ prefix = "WA", min = 3, max = 7 },
	{ center = "P", pin_index = 2, min = 4, max = 7 },
	{ center = "US", min = 4, max = 7 },
	{ center = "W", pin_index = 2, min = 4, max = 7 },
	{ span = { "A", "S" }, min = 3, max = 7 },
	{ center = "LA", min = 4, max = 7 },
	{ center = "O", pin_index = 2, suffix = "K", min = 4, max = 7 },
	{ suffix = "NG", min = 3, max = 7 },
	{ suffix = "TE", min = 3, max = 7 },
	{ prefix = "BU", min = 3, max = 7 },
	{ prefix = "RO", min = 3, max = 7 },
	{ span = { "S", "T" }, min = 3, max = 7 },
}

return M
