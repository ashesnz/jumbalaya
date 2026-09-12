--[[ word_game/ui/table/deck/geometry.lua - 2.5D deck pack projection and mesh helpers ]]

local RIGHT = { x = 0.94, y = 0.04 }
local DEPTH = { x = 0.10, y = -0.52 }
local UP = { x = 0.00, y = -1.00 }

local mesh
local mesh_n

local M = {}

function M.project(w, d, z)
	return w * RIGHT.x + d * DEPTH.x + z * UP.x,
		w * RIGHT.y + d * DEPTH.y + z * UP.y
end

function M.footprint(card_w, card_h, deck)
	local W, D, H = card_w, card_h, deck.MAX_STACK
	local minx, miny = math.huge, math.huge
	local maxx, maxy = -math.huge, -math.huge
	local pts = {
		{ 0, 0, 0 }, { W, 0, 0 }, { W, D, 0 }, { 0, D, 0 },
		{ 0, 0, H }, { W, 0, H }, { W, D, H }, { 0, D, H },
	}
	for i = 1, #pts do
		local sx, sy = M.project(pts[i][1], pts[i][2], pts[i][3])
		if sx < minx then minx = sx end
		if sy < miny then miny = sy end
		if sx > maxx then maxx = sx end
		if sy > maxy then maxy = sy end
	end
	return maxx - minx, maxy - miny + deck.LABEL_H + deck.TOKEN_STACK_H
end

function M.stack_height(n, max_stack)
	if n <= 0 then return 0.04 end
	return math.max(0.14, math.min(max_stack, 0.12 + n * 0.0056))
end

function M.pack_stack_height(deck, card_count)
	card_count = card_count or 0
	if card_count <= 0 then
		return math.max(0.14, M.stack_height(1, deck.MAX_STACK) * 0.85)
	end
	return M.stack_height(card_count, deck.MAX_STACK)
end

function M.snap(px, py)
	return math.floor(px + 0.5), math.floor(py + 0.5)
end

local function arc_wd(pts, cx, cy, r, a0, a1, steps)
	for i = 0, steps do
		local t = a0 + (a1 - a0) * (i / steps)
		pts[#pts + 1] = { cx + r * math.cos(t), cy + r * math.sin(t) }
	end
end

function M.rounded_outline(W, D, r, steps)
	local pts = {}
	arc_wd(pts, W - r, r, r, -math.pi * 0.5, 0, steps)
	arc_wd(pts, W - r, D - r, r, 0, math.pi * 0.5, steps)
	arc_wd(pts, r, D - r, r, math.pi * 0.5, math.pi, steps)
	arc_wd(pts, r, r, r, math.pi, math.pi * 1.5, steps)
	return pts
end

function M.visible_rim(W, D, r, steps)
	local pts = {}
	arc_wd(pts, r, r, r, math.pi, math.pi * 1.5, steps)
	arc_wd(pts, W - r, r, r, -math.pi * 0.5, 0, steps)
	arc_wd(pts, W - r, D - r, r, 0, math.pi * 0.5, steps)
	return pts
end

function M.fill_poly(pts)
	if #pts >= 6 then
		love.graphics.polygon("fill", unpack(pts))
	end
end

function M.back_atlas(area)
	local card = area.cards[1]
	local spr = card and card.children and card.children.back
	if spr and spr.atlas and spr.atlas.image and spr.sprite then
		return spr.atlas, spr.sprite
	end
	return nil
end

function M.ensure_mesh(n)
	if mesh and mesh_n == n then return mesh end
	if mesh then mesh:release() end
	mesh = love.graphics.newMesh(n, "fan", "dynamic")
	mesh_n = n
	return mesh
end

function M.deck_origin_y(area, pack_h, miny, deck)
	local slot_h = area.T.h or 0
	return area.T.y + deck.TOKEN_STACK_H
		+ math.max(0, (slot_h - pack_h - deck.LABEL_H - deck.TOKEN_STACK_H) * deck.DECK_SLOT_Y_ALIGN) - miny
end

function M.pack_bounds(W, D, H)
	local minx, miny = math.huge, math.huge
	local maxx, maxy = -math.huge, -math.huge
	local pts = {
		{ 0, 0, 0 }, { W, 0, 0 }, { W, D, 0 }, { 0, D, 0 },
		{ 0, 0, H }, { W, 0, H }, { W, D, H }, { 0, D, H },
	}
	for i = 1, #pts do
		local sx, sy = M.project(pts[i][1], pts[i][2], pts[i][3])
		if sx < minx then minx = sx end
		if sy < miny then miny = sy end
		if sx > maxx then maxx = sx end
		if sy > maxy then maxy = sy end
	end
	return minx, miny, maxx, maxy
end

return M
