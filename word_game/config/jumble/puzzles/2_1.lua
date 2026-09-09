--[[ word_game/config/jumble_puzzles/2_1.lua
     Jumble puzzle patterns for stage 2-1.
]]

local M = {}

M.PATTERNS = {
	{ span = { "L", "S" }, min = 3, max = 7 },
	{ span = { "M", "E" }, min = 3, max = 7 },
	{ span = { "R", "S" }, min = 3, max = 7 },
	{ center = "ER", min = 4, max = 7 },
	{ center = "O", pin_index = 2, suffix = "N", min = 4, max = 7 },
	{ suffix = "NT", min = 3, max = 7 },
	{ span = { "C", "S" }, min = 3, max = 7 },
	{ prefix = "DA", min = 3, max = 7 },
	{ span = { "M", "S" }, min = 3, max = 7 },
	"C_E__",
	{ prefix = "FR", min = 3, max = 7 },
	{ prefix = "GO", min = 3, max = 7 },
}

return M
