--[[ word_game/config/jumble_puzzles/4_1.lua
     Jumble puzzle patterns for stage 4-1.
]]

local M = {}

M.PATTERNS = {
	"LA__E_",
	"M__E__",
	"RE__E_",
	"R_T___",
	"R__O__",
	"S__KE_",
	"S__RE_",
	"T__N__",
	"WA__E_",
	{ prefix = "WH", min = 3, max = 7 },
	"W_I___",
	{ center = "EF", min = 6, max = 7 },
}

return M
