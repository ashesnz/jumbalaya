--[[
	word_game/ui/table_deck.lua - Draw pile as a pack sitting on the table.

	2.5D table view: cards lie flat, camera looks slightly down from the front.
	Top face is the card back (foreshortened parallelogram, rounded corners).
	A thin stack of paper edges faces the camera — a pack, not a book.
]]

local FONT_FILE = "resources/fonts/Outfit-Bold.ttf"
local ROLL_TIME = 0.38
local TOKEN_HIGHLIGHT_TIME = 0.8
local state = require("word_game.model.state")

local M = {
	SIZE = 0.68,
	MAX_STACK = 0.40,
	LABEL_H = 0.16,
	TOKEN_STACK_H = 0.62,
	TOKEN_DECK_GAP_PX = 14,
	DECK_SLOT_Y_ALIGN = 0.72,
	token_display = nil,
	token_roll = nil,
	token_pending = 0,
	token_highlight = 0,
}

local function clamp01(t)
	if t < 0 then return 0 end
	if t > 1 then return 1 end
	return t
end

local function ease_out(t)
	t = clamp01(t)
	local inv = 1 - t
	return 1 - inv * inv * inv
end

function M.reset()
	M.token_display = nil
	M.token_roll = nil
	M.token_pending = 0
	M.token_highlight = 0
	if WORD_GAME and WORD_GAME.TokenReward and WORD_GAME.TokenReward.reset then
		WORD_GAME.TokenReward.reset()
	end
	if WORD_GAME and WORD_GAME.HandClearFocus and WORD_GAME.HandClearFocus.reset then
		WORD_GAME.HandClearFocus.reset()
	end
end

function M.start_token_roll(from, to)
	if from == to then
		M.token_display = to
		M.token_roll = nil
		return
	end
	M.token_roll = {
		from = from,
		to = to,
		t = 0,
		dur = ROLL_TIME,
	}
end

function M.bump_token_display()
	M.token_pending = (M.token_pending or 0) + 1
	if not M.token_roll then
		local actual = state.tokens()
		local cur = M.token_display
		if cur == nil then cur = math.max(0, actual - 1) end
		M.start_token_roll(cur, cur + 1)
	end
end

function M.spend_tokens_display(amount)
	amount = math.floor(amount or 0)
	if amount <= 0 then return end
	local actual = state.tokens()
	-- The table deck update loop does not run while an overlay marketplace is
	-- open. Publish the purchased balance immediately so the sidebar cannot
	-- remain stale until the overlay closes.
	M.token_display = math.max(0, actual - amount)
	M.token_roll = nil
	M.token_highlight = TOKEN_HIGHLIGHT_TIME
end

function M.is_token_highlighted()
	return (M.token_highlight or 0) > 0
end

function M.token_count()
	if M.token_roll then
		local roll_t = ease_out(M.token_roll.t / M.token_roll.dur)
		if roll_t >= 0.5 then
			return M.token_roll.to
		end
		return M.token_roll.from
	end
	if M.token_display ~= nil then
		return M.token_display
	end
	return state.tokens()
end

function M.update_tokens(dt)
	dt = dt or (G and G.real_dt) or 0.016
	M.token_highlight = math.max(0, (M.token_highlight or 0) - dt)
	local actual = state.tokens()
	if M.token_display == nil then
		M.token_display = actual
	end
	if M.token_roll then
		M.token_roll.t = M.token_roll.t + dt
		if M.token_roll.t >= M.token_roll.dur then
			M.token_display = M.token_roll.to
			M.token_roll = nil
			if (M.token_pending or 0) > 0 then
				M.token_pending = M.token_pending - 1
				M.start_token_roll(M.token_display, M.token_display + 1)
			elseif M.token_display ~= actual then
				M.start_token_roll(M.token_display, actual)
			end
		elseif actual ~= M.token_roll.to then
			M.token_roll.to = actual
		end
	elseif M.token_display ~= actual then
		M.start_token_roll(M.token_display, actual)
	end
end

function M.update(dt, area)
	dt = dt or (G and G.real_dt) or 0.016
	M.update_tokens(dt)
end

-- Table axes in screen tiles: width across the table, depth away, thickness up.
-- Less shear so the top face keeps card proportions instead of stretching wide.
local RIGHT = { x = 0.94, y = 0.04 }
local DEPTH = { x = 0.10, y = -0.52 }
local UP = { x = 0.00, y = -1.00 }

local COL_EDGE = { 0.93, 0.90, 0.84, 1 }
local COL_EDGE_DARK = { 0.78, 0.74, 0.68, 1 }
local COL_RIGHT = { 0.86, 0.83, 0.76, 1 }

local font_cache = {}
local mesh
local mesh_n

function M.uses_table_draw()
	if G.STATE ~= G.STATES.TABLE_BOARD then return false end
	local felt = require("word_game.ui.layout.felt")
	if felt.is_boss_sequence() then return false end
	return true
end

local function project(w, d, z)
	return w * RIGHT.x + d * DEPTH.x + z * UP.x,
		w * RIGHT.y + d * DEPTH.y + z * UP.y
end

function M.footprint(card_w, card_h)
	local W, D, H = card_w, card_h, M.MAX_STACK
	local minx, miny = math.huge, math.huge
	local maxx, maxy = -math.huge, -math.huge
	local pts = {
		{ 0, 0, 0 }, { W, 0, 0 }, { W, D, 0 }, { 0, D, 0 },
		{ 0, 0, H }, { W, 0, H }, { W, D, H }, { 0, D, H },
	}
	for i = 1, #pts do
		local sx, sy = project(pts[i][1], pts[i][2], pts[i][3])
		if sx < minx then minx = sx end
		if sy < miny then miny = sy end
		if sx > maxx then maxx = sx end
		if sy > maxy then maxy = sy end
	end
	return maxx - minx, maxy - miny + M.LABEL_H + M.TOKEN_STACK_H
end

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

local function stack_height(n)
	if n <= 0 then return 0.04 end
	return math.max(0.14, math.min(M.MAX_STACK, 0.12 + n * 0.0056))
end

local function snap(px, py)
	return math.floor(px + 0.5), math.floor(py + 0.5)
end

local function arc_wd(pts, cx, cy, r, a0, a1, steps)
	for i = 0, steps do
		local t = a0 + (a1 - a0) * (i / steps)
		pts[#pts + 1] = { cx + r * math.cos(t), cy + r * math.sin(t) }
	end
end

-- Rounded card in local (width, depth). Depth 0 = near edge (toward camera).
local function rounded_outline(W, D, r, steps)
	local pts = {}
	arc_wd(pts, W - r, r, r, -math.pi * 0.5, 0, steps)
	arc_wd(pts, W - r, D - r, r, 0, math.pi * 0.5, steps)
	arc_wd(pts, r, D - r, r, math.pi * 0.5, math.pi, steps)
	arc_wd(pts, r, r, r, math.pi, math.pi * 1.5, steps)
	return pts
end

-- Near edge + right edge (the two faces a table camera sees).
local function visible_rim(W, D, r, steps)
	local pts = {}
	arc_wd(pts, r, r, r, math.pi, math.pi * 1.5, steps)
	arc_wd(pts, W - r, r, r, -math.pi * 0.5, 0, steps)
	arc_wd(pts, W - r, D - r, r, 0, math.pi * 0.5, steps)
	return pts
end

local function fill_poly(pts)
	if #pts >= 6 then
		love.graphics.polygon("fill", unpack(pts))
	end
end

local function back_atlas(area)
	local card = area.cards[1]
	local spr = card and card.children and card.children.back
	if spr and spr.atlas and spr.atlas.image and spr.sprite then
		return spr.atlas, spr.sprite
	end
	return nil
end

local function ensure_mesh(n)
	if mesh and mesh_n == n then return mesh end
	if mesh then mesh:release() end
	mesh = love.graphics.newMesh(n, "fan", "dynamic")
	mesh_n = n
	return mesh
end


local function deck_origin_y(area, pack_h, miny)
	local slot_h = area.T.h or 0
	return area.T.y + M.TOKEN_STACK_H
		+ math.max(0, (slot_h - pack_h - M.LABEL_H - M.TOKEN_STACK_H) * M.DECK_SLOT_Y_ALIGN) - miny
end

local function tokens_atlas()
	return G.TEXTURE_ATLASES and G.TEXTURE_ATLASES.tokens
end

local function token_layout(area, ox, oy, miny, pack_w, card_w, ts)
	local atlas = tokens_atlas()
	if not atlas or not atlas.image then return end

	local iw, ih = atlas.image:getDimensions()
	if iw <= 0 or ih <= 0 then return end

	local slot_w = (area.T.w or 0) * ts
	local sprite_w = math.min(slot_w * 0.72, card_w * ts * 1.15)
	local sprite_h = sprite_w * (ih / iw)
	local count = M.token_count()
	local label = tostring(count) .. " tokens"
	local label_font = deck_font(math.max(11, math.floor(sprite_w * 0.11)))
	local label_h = label_font:getHeight()
	local label_w = label_font:getWidth(label)
	local stack_h = sprite_h + label_h + 4
	local top_y = (oy + miny) * ts - stack_h - M.TOKEN_DECK_GAP_PX
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

function M.token_center_px(area)
	if not area then return end
	local ts = G.TILESCALE * G.TILESIZE
	local W = G.CARD_W * M.SIZE
	local D = G.CARD_H * M.SIZE
	local n = area.cards and #area.cards or 0
	local H = stack_height(n)
	local r = math.min(W, D) * 0.11

	local minx, miny = math.huge, math.huge
	local maxx, maxy = -math.huge, -math.huge
	do
		local pts = {
			{ 0, 0, 0 }, { W, 0, 0 }, { W, D, 0 }, { 0, D, 0 },
			{ 0, 0, H }, { W, 0, H }, { W, D, H }, { 0, D, H },
		}
		for i = 1, #pts do
			local sx, sy = project(pts[i][1], pts[i][2], pts[i][3])
			if sx < minx then minx = sx end
			if sy < miny then miny = sy end
			if sx > maxx then maxx = sx end
			if sy > maxy then maxy = sy end
		end
	end

	local transform = area.T or { x = 0, y = 0, w = 0, h = 0 }
	local slot_w = transform.w or 0
	local slot_h = transform.h or 0
	local pack_w = maxx - minx
	local pack_h = maxy - miny
	local ox = (transform.x or 0) + math.max(0, (slot_w - pack_w) * 0.5) - minx
	local oy = deck_origin_y(area, pack_h, miny)

	local lay = token_layout(area, ox, oy, miny, pack_w, W, ts)
	if not lay then return end
	return lay.sprite_x + lay.sprite_w * 0.5, lay.sprite_y + lay.sprite_h * 0.5
end

local function draw_tokens(area, ox, oy, miny, pack_w, card_w, ts)
	local lay = token_layout(area, ox, oy, miny, pack_w, card_w, ts)
	if not lay then return end

	local atlas = tokens_atlas()
	local iw, ih = atlas.image:getDimensions()
	local prev_font = love.graphics.getFont()

	local selected = M.is_token_highlighted()
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

function M.draw(area)
	if not area or not area.cards then return end

	local ts = G.TILESCALE * G.TILESIZE
	local W = G.CARD_W * M.SIZE
	local D = G.CARD_H * M.SIZE
	local n = #area.cards
	local H = stack_height(n)
	local r = math.min(W, D) * 0.11

	local minx, miny = math.huge, math.huge
	local maxx, maxy = -math.huge, -math.huge
	do
		local pts = {
			{ 0, 0, 0 }, { W, 0, 0 }, { W, D, 0 }, { 0, D, 0 },
			{ 0, 0, H }, { W, 0, H }, { W, D, H }, { 0, D, H },
		}
		for i = 1, #pts do
			local sx, sy = project(pts[i][1], pts[i][2], pts[i][3])
			if sx < minx then minx = sx end
			if sy < miny then miny = sy end
			if sx > maxx then maxx = sx end
			if sy > maxy then maxy = sy end
		end
	end

	local slot_w = (area.T.w or 0)
	local slot_h = (area.T.h or 0)
	local pack_w = maxx - minx
	local pack_h = maxy - miny
	local ox = area.T.x + math.max(0, (slot_w - pack_w) * 0.5) - minx
	local oy = deck_origin_y(area, pack_h, miny)

	draw_tokens(area, ox, oy, miny, pack_w, W, ts)

	local function to_px(w, d, z)
		local sx, sy = project(w, d, z)
		return snap((ox + sx) * ts, (oy + sy) * ts)
	end

	local outline = rounded_outline(W, D, r, 8)
	local rim = visible_rim(W, D, r, 8)

	if love.graphics.setLineStyle then love.graphics.setLineStyle("smooth") end
	if love.graphics.setLineJoin then love.graphics.setLineJoin("bevel") end
	if love.graphics.setLineWidth then love.graphics.setLineWidth(1) end
	if love.graphics.setShader then love.graphics.setShader() end

	-- Table contact shadow.
	do
		local sh = {}
		for i = 1, #outline do
			local px, py = to_px(outline[i][1], outline[i][2], 0)
			sh[#sh + 1] = px + 4
			sh[#sh + 1] = py + 6
		end
		love.graphics.setColor(0, 0, 0, 0.22)
		fill_poly(sh)
	end

	-- Thin pack sides: near + right, striped like stacked cards.
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
			fill_poly({ x1, y1, x2, y2, x3, y3, x4, y4 })
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

	-- Top face: rounded card back lying on the table.
	local atlas, quad = back_atlas(area)
	if n > 0 and atlas and quad then
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
		local m = ensure_mesh(#verts)
		m:setTexture(atlas.image)
		m:setVertices(verts)
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(m)
	else
		local top = {}
		for i = 1, #outline do
			local px, py = to_px(outline[i][1], outline[i][2], H)
			top[#top + 1] = px
			top[#top + 1] = py
		end
		love.graphics.setColor(n > 0 and 0.72 or 0.18, n > 0 and 0.16 or 0.15, n > 0 and 0.20 or 0.14, n > 0 and 1 or 0.4)
		fill_poly(top)
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

function M.show_info()
	if not M.uses_table_draw() or not G.deck then return end
	local deck = require("word_game.model.cards.deck")
	spawn_attention({
		scale = 0.58,
		text = "Cards left: " .. tostring(deck.cards_left()),
		hold = 2.0,
		align = "cm",
		major = G.deck,
		offset = { x = 0, y = -0.35 },
		colour = G.C.WHITE,
	})
	play_sfx("generic1", 0.88, 0.62)
end

return M
