--[[ word_game/config/jumble_puzzle_1_1.lua
     Jumble puzzle patterns for stage 1-1.
]]

local M = {}

M.PATTERNS = {
	{ span = { "C", "T" }, min = 3, max = 7 },
	{ suffix = "AR", min = 3, max = 7 },
	{ prefix = "C", min = 3, max = 7 },
	{ prefix = "S", min = 3, max = 7 },
	{ suffix = "T", min = 3, max = 7 },
	{ prefix = "O", min = 3, max = 7 },
	{ suffix = "R", min = 3, max = 7 },
	{ suffix = "W", min = 3, max = 7 },
	{ prefix = "N", min = 3, max = 7 },
	{ prefix = "G", min = 3, max = 7 },
}

return M
