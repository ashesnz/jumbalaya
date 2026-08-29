--[[ word_game/ui/perk_voucher.lua - Perk stamp and voucher atlas quads ]]

local cfg = require("word_game.config.perks")

local M = {}

local function atlas()
	return G.TEXTURE_ATLASES and G.TEXTURE_ATLASES.Perk
end

function M.stamp_region(pos)
	local col = (pos and pos.x or 0) + 1
	local row = (pos and pos.y or 0) + 1
	return cfg.STAMP_REGIONS[row][col]
end

function M.stamp_quad(entry)
	local atlas_info = atlas()
	if not atlas_info or not atlas_info.image or not entry or not entry.pos then return end
	local region = M.stamp_region(entry.pos)
	local iw, ih = atlas_info.image:getDimensions()
	return atlas_info.image,
		love.graphics.newQuad(region.x, region.y, region.w, region.h, iw, ih),
		region.w, region.h
end

function M.voucher_grid_pos(pos)
	if not pos then return 1, 1 end
	local col = (pos.x % cfg.VOUCHER_COLS) + 1
	local row = (pos.y % cfg.VOUCHER_ROWS) + 1
	return col, row
end

function M.voucher_region(pos)
	local col, row = M.voucher_grid_pos(pos)
	return cfg.VOUCHER_REGIONS[row][col]
end

function M.voucher_quad(entry)
	local atlas_info = atlas()
	if not atlas_info or not atlas_info.image or not entry or not entry.pos then return end
	local region = M.voucher_region(entry.pos)
	local iw, ih = atlas_info.image:getDimensions()
	return atlas_info.image,
		love.graphics.newQuad(region.x, region.y, region.w, region.h, iw, ih),
		region.w, region.h
end

function M.padding(slot_w, slot_h)
	return math.max(2, math.min(6, math.floor(math.min(slot_w, slot_h) * 0.06)))
end

function M.fit_rect(art_w, art_h, slot_w, slot_h, pad)
	pad = pad or M.padding(slot_w, slot_h)
	local inner_w = math.max(1, slot_w - pad * 2)
	local inner_h = math.max(1, slot_h - pad * 2)
	local scale = math.min(inner_w / art_w, inner_h / art_h)
	local draw_w = art_w * scale
	local draw_h = art_h * scale
	return (slot_w - draw_w) * 0.5, (slot_h - draw_h) * 0.5, draw_w, draw_h
end

function M.draw_stamp(entry, x, y, w, h, alpha)
	alpha = alpha or 1
	local img, quad, pw, ph = M.stamp_quad(entry)
	if not img or not quad then return false end

	local draw_x, draw_y, draw_w, draw_h = M.fit_rect(pw, ph, w, h)
	draw_x = x + draw_x
	draw_y = y + draw_y
	love.graphics.setColor(1, 1, 1, alpha)
	love.graphics.draw(img, quad, draw_x, draw_y, 0, draw_w / pw, draw_h / ph)
	return true
end

function M.draw(entry, x, y, w, h, alpha)
	alpha = alpha or 1
	local img, quad, pw, ph = M.voucher_quad(entry)
	if not img or not quad then return false end

	local draw_x, draw_y, draw_w, draw_h = M.fit_rect(pw, ph, w, h)
	draw_x = x + draw_x
	draw_y = y + draw_y
	love.graphics.setColor(1, 1, 1, alpha)
	love.graphics.draw(img, quad, draw_x, draw_y, 0, draw_w / pw, draw_h / ph)
	return true
end

return M
