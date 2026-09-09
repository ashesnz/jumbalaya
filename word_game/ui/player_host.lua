--[[
	word_game/ui/player_host.lua - Table-board input refresh hooks.

	Legacy character portrait/speech hosts were removed; this module keeps the
	small shared helper still used after layout and play-hold redraws.
]]

local M = {}

function M.refresh_card_input()
	if G.hand and G.hand.set_ranks then G.hand:set_ranks() end
	if G.placement_table and G.placement_table.area and G.placement_table.area.set_ranks then
		G.placement_table.area:set_ranks()
	end
end

return M
