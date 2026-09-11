--[[ word_game/config/jumble_puzzles/3_3.lua
     Jumble puzzle patterns for stage 3-3.
]]

local M = {}

M.PATTERNS = {
	{ suffix = "IC", min = 3, max = 7 },
	{ prefix = "AL", min = 3, max = 7 },
	"A_R___",
	"A__O__",
	"B__N__",
	"C___A_",
	"F_I___",
	"F_N___",
	{ prefix = "GL", min = 3, max = 7 },
	{ prefix = "GRA", min = 3, max = 7 },
	"G_I___",
	{ span = { "G", "R" }, min = 3, max = 7 },
}

return M
