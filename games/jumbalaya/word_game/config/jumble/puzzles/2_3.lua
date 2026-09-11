--[[ word_game/config/jumble_puzzles/2_3.lua
     Jumble puzzle patterns for stage 2-3.
]]

local M = {}

M.PATTERNS = {
	{ center = "NK", min = 5, max = 7 },
	{ center = "NT", min = 5, max = 7 },
	{ center = "OR", min = 5, max = 7 },
	{ center = "TT", min = 5, max = 7 },
	"__T_Y",
	{ suffix = "CE", min = 3, max = 7 },
	{ suffix = "F", min = 3, max = 7 },
	"B_L__",
	"P_A__",
	"P_N__",
	{ prefix = "TH", min = 3, max = 7 },
	"_A__A",
}

return M
