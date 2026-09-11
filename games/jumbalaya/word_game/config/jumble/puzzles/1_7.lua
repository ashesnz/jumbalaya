--[[ word_game/config/jumble_puzzles/1_7.lua
     Jumble puzzle patterns for stage 1-7.
]]

local M = {}

M.PATTERNS = {
	{ prefix = "PA", min = 3, max = 7 },
	{ prefix = "TA", min = 3, max = 7 },
	{ prefix = "TO", min = 3, max = 7 },
	{ suffix = "AW", min = 3, max = 7 },
	{ suffix = "IN", min = 3, max = 7 },
	{ prefix = "HA", min = 3, max = 7 },
	{ span = { "S", "S" }, min = 3, max = 7 },
	{ center = "AI", min = 4, max = 7 },
	{ center = "A", pin_index = 2, suffix = "K", min = 4, max = 7 },
	{ center = "E", pin_index = 2, suffix = "D", min = 4, max = 7 },
	{ prefix = "LI", min = 3, max = 7 },
	{ prefix = "MO", min = 3, max = 7 },
}

return M
