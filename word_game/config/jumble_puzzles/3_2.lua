--[[ word_game/config/jumble_puzzle_3_2.lua
     Jumble puzzle patterns for stage 3-2.
]]

local M = {}

M.PATTERNS = {
	{ center = "AT", min = 4, max = 7 },
	{ center = "C", pin_index = 2, min = 4, max = 7 },
	{ center = "O", pin_index = 2, suffix = "D", min = 4, max = 7 },
	{ center = "O", pin_index = 2, suffix = "L", min = 4, max = 7 },
	{ suffix = "MS", min = 3, max = 7 },
	{ suffix = "NK", min = 3, max = 7 },
	{ span = { "L", "E" }, min = 3, max = 7 },
	{ prefix = "PE", min = 3, max = 7 },
	{ center = "Y", pin_index = 2, min = 5, max = 7 },
	{ suffix = "KE", min = 3, max = 7 },
	{ suffix = "SH", min = 3, max = 7 },
	{ prefix = "MI", min = 3, max = 7 },
}

return M
