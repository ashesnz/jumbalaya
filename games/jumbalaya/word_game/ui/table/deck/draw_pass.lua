--[[ word_game/ui/table/deck/draw_pass.lua - Token label + 2.5D deck pack render ]]

local GameRT = require("word_game.ui.util.game_runtime")
local geometry = require("word_game.ui.table.deck.geometry")
local tokens = require("word_game.ui.table.deck.tokens")

local FONT_FILE = "resources/fonts/Outfit-Bold.ttf"
local COL_EDGE = { 0.93, 0.90, 0.84, 1 }
local COL_EDGE_DARK = { 0.78, 0.74, 0.68, 1 }
local COL_RIGHT = { 0.86, 0.83, 0.76, 1 }

local font_cache = {}
local M = {}

local function runtime() return GameRT.game() end

local function deck_font(px)
	px = math.max(10, math.floor(px + 0.5))
	local cached = font_cache[px]
	if cached then return cached end
	local ok, font = pcall(love.graphics.newFont, FONT_FILE, px)
	if not ok or not font then
		font = love.graphics.newFont(px)
	end
	font:setFilter("linear", "linear")
	font_cache[px] = font
	return font
end

local function tokens_atlas()
	return runtime().TEXTURE_ATLASES and runtime().TEXTURE_ATLASES.tokens
end

local function token_layout(deck, area, ox, oy, miny, pack_w, card_w, ts)
	local atlas = tokens_atlas()
	if not atlas or not atlas.image then return end

	local iw, ih = atlas.image:getDimensions()
	if iw <= 0 or ih <= 0 then return end

	local slot_w = (area.T.w or 0) * ts
	local sprite_w = math.min(slot_w * 0.72, card_w * ts * 1.15)
	local sprite_h = sprite_w * (ih / iw)
	local count = tokens.token_count(deck)
	local label = tostring(count) .. " tokens"
	local label_font = deck_font(math.max(11, math.floor(sprite_w * 0.11)))
	local label_h = label_font:getHeight()
	local label_w = label_font:getWidth(label)
	local stack_h = sprite_h + label_h + 4
	local top_y = (oy + miny) * ts - stack_h - deck.TOKEN_DECK_GAP_PX
	local sprite_x = area.T.x * ts + (slot_w - sprite_w) * 0.5
	local label_x = area.T.x * ts + (slot_w - label_w) * 0.5
	local label_y = top_y + sprite_h + 2

	return {
		sprite_x = sprite_x,
		sprite_y = top_y,
		sprite_w = sprite_w,
		sprite_h = sprite_h,
		label_x = label_x,
		label_y = label_y,
		label = label,
		label_font = label_font,
	}
end

local function draw_tokens(deck, area, ox, oy, miny, pack_w, card_w, ts)
	local lay = token_layout(deck, area, ox, oy, miny, pack_w, card_w, ts)
	if not lay then return end

	local atlas = tokens_atlas()
	local iw, ih = atlas.image:getDimensions()
	local prev_font = love.graphics.getFont()

	local selected = tokens.is_token_highlighted(deck)
	love.graphics.setColor(selected and 1 or 0.82, selected and 1 or 0.82, selected and 1 or 0.82, 1)
	love.graphics.draw(
		atlas.image,
		lay.sprite_x,
		lay.sprite_y,
		0,
		lay.sprite_w / iw,
		lay.sprite_h / ih
	)

	love.graphics.setFont(lay.label_font)
	love.graphics.setColor(0, 0, 0, 0.65)
	love.graphics.print(lay.label, lay.label_x + 1, lay.label_y + 1)
	if selected then
		love.graphics.setColor(1, 1, 0.78, 1)
	else
		love.graphics.setColor(0.96, 0.90, 0.55, 1)
	end
	love.graphics.print(lay.label, lay.label_x, lay.label_y)

	if prev_font then love.graphics.setFont(prev_font) end
	love.graphics.setColor(1, 1, 1, 1)
end

function M.token_center_px(deck, area)
	if not area then return end
	local ts = runtime().TILESCALE * runtime().TILESIZE
	local W = runtime().CARD_W * deck.SIZE
	local D = runtime().CARD_H * deck.SIZE
	local n = area.cards and #area.cards or 0
	local H = geometry.pack_stack_height(deck, n)
	local minx, miny, maxx, maxy = geometry.pack_bounds(W, D, H)
	local transform = area.T or { x = 0, y = 0, w = 0, h = 0 }
	local slot_w = transform.w or 0
	local pack_w = maxx - minx
	local pack_h = maxy - miny
	local ox = (transform.x or 0) + math.max(0, (slot_w - pack_w) * 0.5) - minx
	local oy = geometry.deck_origin_y(area, pack_h, miny, deck)

	local lay = token_layout(deck, area, ox, oy, miny, pack_w, W, ts)
	if not lay then return end
	return lay.sprite_x + lay.sprite_w * 0.5, lay.sprite_y + lay.sprite_h * 0.5
end

function M.draw(deck, area)
	if not area or not area.cards then return end

	local ts = runtime().TILESCALE * runtime().TILESIZE
	local W = runtime().CARD_W * deck.SIZE
	local D = runtime().CARD_H * deck.SIZE
	local n = #area.cards
	local H = geometry.pack_stack_height(deck, n)
	local r = math.min(W, D) * 0.11

	local minx, miny, maxx, maxy = geometry.pack_bounds(W, D, H)
	local slot_w = (area.T.w or 0)
	local pack_w = maxx - minx
	local pack_h = maxy - miny
	local ox = area.T.x + math.max(0, (slot_w - pack_w) * 0.5) - minx
	local oy = geometry.deck_origin_y(area, pack_h, miny, deck)

	draw_tokens(deck, area, ox, oy, miny, pack_w, W, ts)

	local function to_px(w, d, z)
		local sx, sy = geometry.project(w, d, z)
		return geometry.snap((ox + sx) * ts, (oy + sy) * ts)
	end

	local outline = geometry.rounded_outline(W, D, r, 8)
	local rim = geometry.visible_rim(W, D, r, 8)

	if love.graphics.setLineStyle then love.graphics.setLineStyle("smooth") end
	if love.graphics.setLineJoin then love.graphics.setLineJoin("bevel") end
	if love.graphics.setLineWidth then love.graphics.setLineWidth(1) end
	if love.graphics.setShader then love.graphics.setShader() end

	do
		local sh = {}
		for i = 1, #outline do
			local px, py = to_px(outline[i][1], outline[i][2], 0)
			sh[#sh + 1] = px + 4
			sh[#sh + 1] = py + 6
		end
		love.graphics.setColor(0, 0, 0, 0.22)
		geometry.fill_poly(sh)
	end

	local stripes = math.max(6, math.min(36, math.floor(n * 0.55)))
	for s = stripes, 1, -1 do
		local z0 = H * ((s - 1) / stripes)
		local z1 = H * (s / stripes)
		local even = s % 2 == 0
		for i = 1, #rim - 1 do
			local a, b = rim[i], rim[i + 1]
			local mid_w = (a[1] + b[1]) * 0.5
			local on_right = mid_w > W * 0.72
			if on_right then
				love.graphics.setColor(COL_RIGHT)
			elseif even then
				love.graphics.setColor(COL_EDGE_DARK)
			else
				love.graphics.setColor(COL_EDGE)
			end
			local x1, y1 = to_px(a[1], a[2], z0)
			local x2, y2 = to_px(b[1], b[2], z0)
			local x3, y3 = to_px(b[1], b[2], z1)
			local x4, y4 = to_px(a[1], a[2], z1)
			geometry.fill_poly({ x1, y1, x2, y2, x3, y3, x4, y4 })
		end
	end

	love.graphics.setColor(0.28, 0.22, 0.18, 0.55)
	love.graphics.setLineWidth(1)
	for i = 1, #rim - 1 do
		local a, b = rim[i], rim[i + 1]
		local x1, y1 = to_px(a[1], a[2], 0)
		local x2, y2 = to_px(b[1], b[2], 0)
		love.graphics.line(x1, y1, x2, y2)
	end

	local atlas, quad = geometry.back_atlas(area)
	if atlas and quad then
		local qx, qy, qw, qh = quad:getViewport()
		local iw, ih = atlas.image:getDimensions()
		local u1, v1 = qx / iw, qy / ih
		local u2, v2 = (qx + qw) / iw, (qy + qh) / ih
		local cx, cy = to_px(W * 0.5, D * 0.5, H)
		local verts = {
			{ cx, cy, (u1 + u2) * 0.5, (v1 + v2) * 0.5, 1, 1, 1, 1 },
		}
		for i = 1, #outline do
			local p = outline[i]
			local px, py = to_px(p[1], p[2], H)
			local u = u1 + (p[1] / W) * (u2 - u1)
			local v = v2 - (p[2] / D) * (v2 - v1)
			verts[#verts + 1] = { px, py, u, v, 1, 1, 1, 1 }
		end
		verts[#verts + 1] = verts[2]
		local mesh = geometry.ensure_mesh(#verts)
		mesh:setTexture(atlas.image)
		mesh:setVertices(verts)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(mesh)
	else
		local top = {}
		for i = 1, #outline do
			local px, py = to_px(outline[i][1], outline[i][2], H)
			top[#top + 1] = px
			top[#top + 1] = py
		end
		love.graphics.setColor(n > 0 and 0.72 or 0.18, n > 0 and 0.16 or 0.15, n > 0 and 0.20 or 0.14, n > 0 and 1 or 0.4)
		geometry.fill_poly(top)
	end

	love.graphics.setColor(0.14, 0.10, 0.08, 0.95)
	love.graphics.setLineWidth(1.5)
	local top_line = {}
	for i = 1, #outline do
		local px, py = to_px(outline[i][1], outline[i][2], H)
		top_line[#top_line + 1] = px
		top_line[#top_line + 1] = py
	end
	if #top_line >= 4 then
		top_line[#top_line + 1] = top_line[1]
		top_line[#top_line + 1] = top_line[2]
		love.graphics.line(unpack(top_line))
	end

	love.graphics.setLineStyle("smooth")
	love.graphics.setLineWidth(1)
	love.graphics.setColor(1, 1, 1, 1)
end

return M
