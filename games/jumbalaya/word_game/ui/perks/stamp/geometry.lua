--[[ word_game/ui/perks/stamp/geometry.lua - Stamp panel and cell layout in screen space ]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local Layout = require("word_game.ui.layout")
local stamp_layout = require("word_game.ui.perks.stamp.layout")
local stamp_grid = require("word_game.ui.perks.stamp.grid")
local animate = require("word_game.ui.perks.stamp.animate")

local M = {}

local node_rect_px = stamp_layout.node_rect_px
local tile_scale = stamp_layout.tile_scale
local sidebar_width_px = stamp_layout.sidebar_width_px
local mouse_to_stamp_space = stamp_layout.mouse_to_stamp_space

function M.layout_stamp_count()
	return animate.layout_stamp_count()
end

function M.next_slot_index()
	return animate.next_slot_index()
end

function M.stamp_panel_rect_px(layout_count)
	layout_count = layout_count or M.layout_stamp_count()
	local row
	local views_install = require("word_game.ui.views.install")
	local sidebar_view = views_install.sidebar_view()
	if sidebar_view and sidebar_view.find_node_by_id then
		row = sidebar_view:find_node_by_id("row_stamp_slot")
	end
	if not row and runtime().SIDEBAR_HUD and runtime().SIDEBAR_HUD.find_node_by_id then
		row = runtime().SIDEBAR_HUD:find_node_by_id("row_stamp_slot")
	end
	local rx, ry, rw, rh = node_rect_px(row)
	if not rx then
		local sidebar = Layout.sidebar_rect()
		local ts = tile_scale()
		rx = sidebar.x * ts
		ry = (sidebar.y + 0.82) * ts
		rw = sidebar.w * ts
		rh = stamp_grid.panel_height_px(nil, layout_count)
	end
	local w = sidebar_width_px()
	local h = stamp_grid.panel_height_px(nil, layout_count)
	local box_h = math.max(rh or h, h)
	local x = rx + (rw - w) * 0.5
	local y = ry + (box_h - h) * 0.5
	return x, y, w, h, layout_count
end

function M.stamp_cell_rect_px(index)
	index = index or M.next_slot_index()
	local count = math.max(index, M.layout_stamp_count())
	local panel_x, panel_y, panel_w, panel_h = M.stamp_panel_rect_px(count)
	return stamp_grid.cell_rect_px(panel_x, panel_y, panel_w, panel_h, index, count)
end

function M.stamp_target_px(target_index)
	target_index = target_index or M.next_slot_index()
	local x, y, w, h = M.stamp_cell_rect_px(target_index)
	return x + w * 0.5, y + h * 0.5, x, y, w, h
end

function M.imprint_index_at(mx, my)
	local imprints = animate.get_imprints()
	if #imprints == 0 then return nil end
	local sx, sy = mouse_to_stamp_space(mx, my)
	for i = 1, #imprints do
		local x, y, w, h = M.stamp_cell_rect_px(i)
		if sx >= x and sx <= x + w and sy >= y and sy <= y + h then
			return i
		end
	end
	return nil
end

function M.debug_grid_layout(count)
	local panel_x, panel_y, panel_w = M.stamp_panel_rect_px()
	count = count or M.layout_stamp_count()
	return stamp_grid.layout(panel_x, panel_y, panel_w, count)
end

return M
