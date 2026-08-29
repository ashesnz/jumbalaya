--[[ word_game/ui/stamp_grid.lua - Single vault stamp panel layout ]]

local Layout = require("word_game.ui.layout")
local perk_cfg = require("word_game.config.perks")

local M = {}

M.CELL_W_PX = perk_cfg.STAMP_CELL_W_PX or 71
M.CELL_H_PX = perk_cfg.STAMP_CELL_H_PX or 95
M.ASPECT = M.CELL_H_PX / M.CELL_W_PX

local REF_TILE_PX = 71

function M.tile_scale()
	return (G.TILESCALE or 1) * (G.TILESIZE or 1)
end

function M.pad_px()
	return math.max(2, 4 * M.tile_scale() / REF_TILE_PX)
end

function M.vault_width_px()
	return Layout.sidebar_width() * M.tile_scale()
end

function M.cell_width_px(panel_w)
	panel_w = panel_w or M.vault_width_px()
	return panel_w - M.pad_px() * 2
end

function M.cell_height_px(cell_w)
	cell_w = cell_w or M.cell_width_px()
	return cell_w * M.ASPECT
end

function M.panel_height_px(panel_w)
	panel_w = panel_w or M.vault_width_px()
	local pad = M.pad_px()
	return M.cell_height_px(M.cell_width_px(panel_w)) + pad * 2
end

function M.panel_height_tiles()
	return M.panel_height_px() / M.tile_scale() + 0.04
end

function M.cell_rect_px(panel_x, panel_y, panel_w, panel_h)
	panel_w = panel_w or M.vault_width_px()
	panel_h = panel_h or M.panel_height_px(panel_w)
	panel_x = panel_x or 0
	panel_y = panel_y or 0
	local pad = M.pad_px()
	local cell_w = M.cell_width_px(panel_w)
	local cell_h = M.cell_height_px(cell_w)
	return panel_x + pad, panel_y + pad, cell_w, cell_h
end

function M.layout(panel_x, panel_y, panel_w)
	panel_x = panel_x or 0
	panel_y = panel_y or 0
	panel_w = panel_w or M.vault_width_px()
	local panel_h = M.panel_height_px(panel_w)
	local x, y, w, h = M.cell_rect_px(panel_x, panel_y, panel_w, panel_h)
	return {
		panel = { x = panel_x, y = panel_y, w = panel_w, h = panel_h },
		cell_w = w,
		cell_h = h,
		cell = { x = x, y = y, w = w, h = h },
	}
end

return M
