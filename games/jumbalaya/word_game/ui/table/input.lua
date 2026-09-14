--[[ word_game/ui/table/input.lua - Refresh hand/placement drag ranks after layout changes ]]

local game = require("word_game.ui.util.game_runtime").game

local M = {}

function M.refresh_card_input()
	if game().dealt_letters and game().dealt_letters.set_ranks then game().dealt_letters:set_ranks() end
	if game().pattern_row and game().pattern_row.area and game().pattern_row.area.set_ranks then
		game().pattern_row.area:set_ranks()
	end
end

return M
