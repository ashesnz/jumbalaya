--[[ word_game/config/jumble_puzzles/8_1.lua
     Jumble puzzle patterns for stage 8-1.
]]

local M = {}

M.PATTERNS = {
	"S____S_",
	"T__A___",
	"T___A__",
	{ span = { "U", "D" }, min = 3, max = 7 },
	"V___I__",
	{ center = "ANG", min = 7, max = 7 },
	{ center = "ART", min = 7, max = 7 },
	"_A_RI__",
	"_A_U___",
	"_A__L_S",
	"_E_DI__",
	"_E_T_R_",
}

return M
