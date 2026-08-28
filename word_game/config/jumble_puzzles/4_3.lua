--[[ word_game/config/jumble_puzzles/4_3.lua
     Jumble puzzle patterns for stage 4-3.
]]

local M = {}

M.PATTERNS = {
	"__U__D",
	{ suffix = "ATE", min = 3, max = 7 },
	{ suffix = "DLE", min = 3, max = 7 },
	{ suffix = "HER", min = 3, max = 7 },
	"___L_Y",
	"___S_R",
	{ suffix = "TES", min = 3, max = 7 },
	"A_T___",
	"A___A_",
	"BO__E_",
	"CA___S",
	"C__A__",
}

return M
