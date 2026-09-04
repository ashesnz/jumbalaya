--[[ word_game/ui/perks/stamp_grid.lua - Vault stamp stack layout ]]

local Layout = require("word_game.ui.layout")
local perk_cfg = require("word_game.config.perks")

local M = {}

M.SLOT_WIDTH_FRAC = perk_cfg.STAMP_SLOT_WIDTH_FRAC
M.SLOT_ASPECT = perk_cfg.STAMP_SLOT_ASPECT

local REF_TILE_PX = 71

function M.tile_scale()
	return (G.TILESCALE or 1) * (G.TILESIZE or 1)
end

function M.pad_px()
	return math.max(2, 4 * M.tile_scale() / REF_TILE_PX)
end

function M.gap_px()
	return math.max(3, 5 * M.tile_scale() / REF_TILE_PX)
end

function M.vault_width_px()
	return Layout.sidebar_width() * M.tile_scale()
end

function M.slot_size_px(panel_w)
	panel_w = panel_w or M.vault_width_px()
	local w = panel_w * M.SLOT_WIDTH_FRAC
	local h = w * M.SLOT_ASPECT
	return w, h
end

function M.stack_height_px(panel_w, count)
	count = math.max(1, count or 1)
	panel_w = panel_w or M.vault_width_px()
	local _, slot_h = M.slot_size_px(panel_w)
	local gap = M.gap_px()
	return count * slot_h + math.max(0, count - 1) * gap
end

function M.panel_height_px(panel_w, count)
	panel_w = panel_w or M.vault_width_px()
	count = math.max(1, count or 1)
	return M.stack_height_px(panel_w, count) + M.pad_px() * 2
end

function M.panel_height_tiles(count)
	return M.panel_height_px(nil, count) / M.tile_scale() + 0.04
end

function M.cell_rect_px(panel_x, panel_y, panel_w, panel_h, index, count)
	panel_w = panel_w or M.vault_width_px()
	count = math.max(1, count or index or 1)
	index = math.max(1, math.min(index or 1, count))
	panel_h = panel_h or M.panel_height_px(panel_w, count)
	panel_x = panel_x or 0
	panel_y = panel_y or 0
	local slot_w, slot_h = M.slot_size_px(panel_w)
	local gap = M.gap_px()
	local stack_h = M.stack_height_px(panel_w, count)
	local x = panel_x + (panel_w - slot_w) * 0.5
	local y = panel_y + (panel_h - stack_h) * 0.5 + (index - 1) * (slot_h + gap)
	return x, y, slot_w, slot_h
end

function M.layout(panel_x, panel_y, panel_w, count)
	panel_x = panel_x or 0
	panel_y = panel_y or 0
	panel_w = panel_w or M.vault_width_px()
	count = math.max(1, count or 1)
	local panel_h = M.panel_height_px(panel_w, count)
	local cells = {}
	for i = 1, count do
		local x, y, w, h = M.cell_rect_px(panel_x, panel_y, panel_w, panel_h, i, count)
		cells[i] = { x = x, y = y, w = w, h = h }
	end
	local last = cells[count]
	return {
		panel = { x = panel_x, y = panel_y, w = panel_w, h = panel_h },
		count = count,
		cells = cells,
		cell_w = last.w,
		cell_h = last.h,
		cell = last,
	}
end

return M
