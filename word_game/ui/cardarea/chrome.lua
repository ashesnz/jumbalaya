--[[ word_game/ui/cardarea/chrome.lua - Optional card-count badge UI for card areas ]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local UIViewHost = require("word_game.ui.views.ui_view_host")

local M = {}

function M.ensure_area_uibox(area)
	if area.children.area_uibox then return end

	local show_count = area ~= runtime().dealt_letters
	local placement_area = runtime().pattern_row and runtime().pattern_row.area
	local card_count = show_count and {n=runtime().UI.ROW, config={align = area == placement_area and 'cl' or 'cr', padding = 0.03, no_fill = true}, nodes={
		{n=runtime().UI.BOX, config={w = 0.1,h=0.1}},
		{n=runtime().UI.TEXT, config={ref_table = area.config, ref_value = 'card_count', scale = 0.3, colour = runtime().C.WHITE}},
		{n=runtime().UI.TEXT, config={text = '/', scale = 0.3, colour = runtime().C.WHITE}},
		{n=runtime().UI.TEXT, config={ref_table = area.config, ref_value = 'card_limit', scale = 0.3, colour = runtime().C.WHITE}},
		{n=runtime().UI.BOX, config={w = 0.1,h=0.1}}
	}} or nil

	area.children.area_uibox = UIViewHost.create{
		definition =
			{n=runtime().UI.ROOT, config = {align = 'cm', colour = runtime().C.CLEAR}, nodes={
				{n=runtime().UI.ROW, config={minw = area.T.w,minh = area.T.h,align = "cm", padding = 0.1, mid = true, r = 0.1, colour = {0,0,0,0.1}, ref_table = area}, nodes={}},
				card_count
			}},
		config = { align = 'cm', offset = {x=0,y=0}, major = area, parent = area}
	}
end

function M.draw_chrome(area)
	if area == runtime().dealt_letters and area.children.area_uibox and not area.config.hide_card_count then
		area.children.area_uibox:remove()
		area.children.area_uibox = nil
	end
	if area == runtime().dealt_letters then
		area.config.hide_card_count = true
	end
	M.ensure_area_uibox(area)
	local skip_pad = area == runtime().draw_pile and WORD_GAME_UI.TableDeck
		and WORD_GAME_UI.TableDeck.uses_table_draw()
	if not skip_pad then
		area.children.area_uibox:draw()
	end
end

return M
