--[[ word_game/config/jumble_puzzles/7_1.lua
     Jumble puzzle patterns for stage 7-1.
]]

local M = {}

M.PATTERNS = {
	"C__M__",
	"C__P__",
	"C___R_",
	"D___L_",
	"D___N_",
	"GR___S",
	"G___ER",
	"G___ES",
	{ prefix = "KI", min = 3, max = 7 },
	"M_L___",
	"A____ES",
	"B_A__E_",
}

return M
