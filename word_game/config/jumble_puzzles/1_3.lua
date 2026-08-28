--[[ word_game/config/jumble_puzzles/1_3.lua
     Jumble puzzle patterns for stage 1-3.
]]

local M = {}

M.BOSS_WORDS = {
	"SUNFLOWER", "BUTTERFLY", "VEGETABLE", "GARDENING", "POLLINATE",
	"RAINDROPS", "DRAGONFLY", "FLOWERPOT", "HERBICIDE",
}

M.PATTERNS = {
	{ center = "C", min = 3, max = 7 },
	{ center = "H", min = 3, max = 7 },
	{ center = "W", min = 3, max = 7 },
	{ center = "M", min = 3, max = 7 },
	{ suffix = "L", min = 3, max = 7 },
	{ suffix = "H", min = 3, max = 7 },
	{ prefix = "J", min = 3, max = 7 },
	{ prefix = "V", min = 3, max = 7 },
	{ suffix = "AY", min = 3, max = 7 },
	{ suffix = "OT", min = 3, max = 7 },
	{ center = "T", min = 3, max = 7 },
	{ prefix = "CO", min = 3, max = 7 },
}

return M
