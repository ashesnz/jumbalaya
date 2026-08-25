--[[ word_game/config/jumble_puzzle_5_2.lua
     Jumble puzzle patterns for stage 5-2.
]]

local M = {}

M.PATTERNS = {
	{ prefix = "DU", min = 3, max = 7 },
	"G_O__",
	{ prefix = "PU", min = 3, max = 7 },
	"_IL_S",
	{ center = "IS", min = 5, max = 7 },
	"_L_E_",
	"_O_TS",
	"__A_Y",
	"__N_E",
	"__O_T",
	"__U_T",
	{ suffix = "FS", min = 3, max = 7 },
}

return M
