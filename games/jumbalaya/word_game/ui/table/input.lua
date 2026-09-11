--[[ word_game/ui/table/input.lua - Refresh hand/placement drag ranks after layout changes ]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local M = {}

function M.refresh_card_input()
	if runtime().dealt_letters and runtime().dealt_letters.set_ranks then runtime().dealt_letters:set_ranks() end
	if runtime().pattern_row and runtime().pattern_row.area and runtime().pattern_row.area.set_ranks then
		runtime().pattern_row.area:set_ranks()
	end
end

return M
