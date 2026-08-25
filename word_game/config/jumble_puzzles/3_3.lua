--[[ word_game/config/jumble_puzzle_3_3.lua
     Jumble puzzle patterns for stage 3-3.
]]

local M = {}

M.PATTERNS = {
	{ prefix = "RA", min = 3, max = 7 },
	{ span = { "R", "E" }, min = 3, max = 7 },
	{ prefix = "SO", min = 3, max = 7 },
	{ center = "AM", min = 4, max = 7 },
	{ center = "EL", min = 4, max = 7 },
	{ center = "IT", min = 4, max = 7 },
	{ center = "I", pin_index = 2, suffix = "T", min = 4, max = 7 },
	{ center = "LO", min = 4, max = 7 },
	{ center = "OS", min = 4, max = 7 },
	{ center = "U", pin_index = 2, suffix = "K", min = 4, max = 7 },
	{ prefix = "DI", min = 3, max = 7 },
	{ span = { "D", "S" }, min = 3, max = 7 },
}

return M
