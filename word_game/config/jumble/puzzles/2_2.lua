--[[ word_game/config/jumble_puzzles/2_2.lua
     Jumble puzzle patterns for stage 2-2.
]]

local M = {}

M.PATTERNS = {
	"M_N__",
	"P_R__",
	{ span = { "S", "D" }, min = 3, max = 7 },
	{ center = "AP", min = 5, max = 7 },
	{ center = "AV", min = 5, max = 7 },
	"_E_L_",
	{ center = "IR", min = 5, max = 7 },
	"_OL_S",
	"_O__H",
	{ center = "AL", min = 5, max = 7 },
	{ center = "AM", min = 5, max = 7 },
	{ center = "BE", min = 5, max = 7 },
}

return M
