--[[ word_game/ui/cardarea/chrome.lua - Optional card-count badge UI for card areas ]]

local M = {}

function M.ensure_area_uibox(area)
	if area.children.area_uibox then return end

	local show_count = area ~= G.hand
	local placement_area = G.placement_table and G.placement_table.area
	local card_count = show_count and {n=G.UI.ROW, config={align = area == placement_area and 'cl' or 'cr', padding = 0.03, no_fill = true}, nodes={
		{n=G.UI.BOX, config={w = 0.1,h=0.1}},
		{n=G.UI.TEXT, config={ref_table = area.config, ref_value = 'card_count', scale = 0.3, colour = G.C.WHITE}},
		{n=G.UI.TEXT, config={text = '/', scale = 0.3, colour = G.C.WHITE}},
		{n=G.UI.TEXT, config={ref_table = area.config, ref_value = 'card_limit', scale = 0.3, colour = G.C.WHITE}},
		{n=G.UI.BOX, config={w = 0.1,h=0.1}}
	}} or nil

	area.children.area_uibox = LayoutView{
		definition =
			{n=G.UI.ROOT, config = {align = 'cm', colour = G.C.CLEAR}, nodes={
				{n=G.UI.ROW, config={minw = area.T.w,minh = area.T.h,align = "cm", padding = 0.1, mid = true, r = 0.1, colour = {0,0,0,0.1}, ref_table = area}, nodes={}},
				card_count
			}},
		config = { align = 'cm', offset = {x=0,y=0}, major = area, parent = area}
	}
end

function M.draw_chrome(area)
	if area == G.hand and area.children.area_uibox and not area.config.hide_card_count then
		area.children.area_uibox:remove()
		area.children.area_uibox = nil
	end
	if area == G.hand then
		area.config.hide_card_count = true
	end
	M.ensure_area_uibox(area)
	local skip_pad = area == G.deck and WORD_GAME and WORD_GAME.TableDeck
		and WORD_GAME.TableDeck.uses_table_draw()
	if not skip_pad then
		area.children.area_uibox:draw()
	end
end

return M
