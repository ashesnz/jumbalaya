--[[ word_game/config/jumble_puzzle_7_3.lua
     Jumble puzzle patterns for stage 7-3.
]]

local M = {}

M.PATTERNS = {
	"HA__I__",
	{ span = { "H", "D" }, min = 3, max = 7 },
	"I__E___",
	{ span = { "I", "E" }, min = 3, max = 7 },
	"MA___E_",
	"M__A___",
	"M__S___",
	"O___I__",
	"R_F____",
	"R_N____",
	"R___O__",
	"S___M__",
}

return M
