--[[ word_game/ui/table/input.lua - Refresh hand/placement drag ranks after layout changes ]]

local M = {}

function M.refresh_card_input()
	if G.dealt_letters and G.dealt_letters.set_ranks then G.dealt_letters:set_ranks() end
	if G.pattern_row and G.pattern_row.area and G.pattern_row.area.set_ranks then
		G.pattern_row.area:set_ranks()
	end
end

return M
