--[[ word_game/ui/table_input.lua - Refresh hand/placement drag ranks after layout changes. ]]

local M = {}

function M.refresh_card_input()
	if G.hand and G.hand.set_ranks then G.hand:set_ranks() end
	if G.placement_table and G.placement_table.area and G.placement_table.area.set_ranks then
		G.placement_table.area:set_ranks()
	end
end

return M
