--[[ word_game/ui/perks/voucher.lua - Perk stamp and voucher atlas quads ]]

local cfg = require("word_game.config.perks")

local M = {}

local function atlas()
	return G.TEXTURE_ATLASES and G.TEXTURE_ATLASES.Perk
end

function M.voucher_grid_pos(pos)
	if not pos then return 1, 1 end
	local col = (pos.x % cfg.VOUCHER_COLS) + 1
	local row = (pos.y % cfg.VOUCHER_ROWS) + 1
	return col, row
end

function M.stamp_region(pos)
	local col, row = M.voucher_grid_pos(pos)
	return cfg.STAMP_REGIONS[row][col]
end

function M.voucher_region(pos)
	local col, row = M.voucher_grid_pos(pos)
	return cfg.VOUCHER_REGIONS[row][col]
end

--- Map an authored Perks.png region into the live atlas's logical pixel space.
function M.region_in_atlas(region, iw, ih)
	if not region or not iw or not ih or iw <= 0 or ih <= 0 then return nil end
	local sx = iw / (cfg.SHEET_W or iw)
	local sy = ih / (cfg.SHEET_H or ih)
	local x = region.x * sx
	local y = region.y * sy
	local w = region.w * sx
	local h = region.h * sy
	if x < 0 then
		w = w + x
		x = 0
	end
	if y < 0 then
		h = h + y
		y = 0
	end
	if x + w > iw then w = iw - x end
	if y + h > ih then h = ih - y end
	if w <= 0 or h <= 0 then return nil end
	return x, y, w, h
end

local function atlas_quad(region)
	local atlas_info = atlas()
	if not atlas_info or not atlas_info.image or not region then return end
	if not love or not love.graphics or not love.graphics.newQuad then return end
	local iw, ih = atlas_info.image:getDimensions()
	local x, y, w, h = M.region_in_atlas(region, iw, ih)
	if not x then return end
	return atlas_info.image, love.graphics.newQuad(x, y, w, h, iw, ih), w, h
end

function M.stamp_quad(entry)
	if not entry or not entry.pos then return end
	return atlas_quad(M.stamp_region(entry.pos))
end

function M.voucher_quad(entry)
	if not entry or not entry.pos then return end
	return atlas_quad(M.voucher_region(entry.pos))
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
