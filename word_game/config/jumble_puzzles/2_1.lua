--[[ word_game/config/jumble_puzzle_2_1.lua
     Jumble puzzle patterns for stage 2-1.
]]

local M = {}

M.PATTERNS = {
	{ prefix = "U", min = 3, max = 7 },
	{ suffix = "AD", min = 3, max = 7 },
	{ suffix = "AG", min = 3, max = 7 },
	{ suffix = "AP", min = 3, max = 7 },
	{ center = "F", min = 3, max = 7 },
	{ center = "N", min = 3, max = 7 },
	{ suffix = "OB", min = 3, max = 7 },
	{ suffix = "OW", min = 3, max = 7 },
	{ prefix = "MA", min = 3, max = 7 },
	{ suffix = "AT", min = 3, max = 7 },
	{ center = "B", min = 3, max = 7 },
	{ suffix = "IT", min = 3, max = 7 },
}

return M
