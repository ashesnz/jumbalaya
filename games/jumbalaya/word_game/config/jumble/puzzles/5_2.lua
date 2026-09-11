--[[ word_game/config/jumble_puzzles/5_2.lua
     Jumble puzzle patterns for stage 5-2.
]]

local M = {}

M.PATTERNS = {
	"B_E____",
	"B___H__",
	{ span = { "B", "Y" }, min = 3, max = 7 },
	"CA___E_",
	"CO__O__",
	"C_P____",
	"C___R__",
	"C___S__",
	"DI____S",
	"D__E___",
	"D___ER_",
	"F__S___",
}

return M
