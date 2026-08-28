--[[ word_game/config/jumble_puzzles/3_1.lua
     Jumble puzzle patterns for stage 3-1.
]]

local M = {}

M.PATTERNS = {
	"_E_I_",
	"_I_K_",
	"_R__D",
	{ center = "GE", min = 5, max = 7 },
	"__O_Y",
	{ suffix = "DE", min = 3, max = 7 },
	{ suffix = "NE", min = 3, max = 7 },
	{ suffix = "RE", min = 3, max = 7 },
	"A_I__",
	"A_O__",
	{ prefix = "CU", min = 3, max = 7 },
	"C_U__",
}

return M
