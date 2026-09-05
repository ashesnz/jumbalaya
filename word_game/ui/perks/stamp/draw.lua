--[[ word_game/ui/perks/stamp/draw.lua - 3D rubber-stamp geometry and rendering ]]

local perk_voucher = require("word_game.ui.perks.voucher")

local M = {}

M.SLOT_WIDTH_FILL = 0.92

-- 3/4 view: long axis stays horizontal so the block matches the vault row.
-- Roll is the slight diagonal tilt of a hand coming down from above-right.
M.LANDING_YAW = 0.32
M.LANDING_PITCH = 0.26
M.LANDING_ROLL = -0.06
M.START_YAW = 0.50
M.START_PITCH = 0.48
M.START_ROLL = -0.22

-- Local-space millimetres of the wooden block (x right, y up, z toward camera).
local BODY_W = 96
local BODY_H = 22
local BODY_D = 42
local RUBBER_H = 7
local HANDLE_R = 7
local HANDLE_H = 22

local WOOD_TOP = { 0.65, 0.44, 0.23 }
local WOOD_FRONT = { 0.58, 0.38, 0.20 }
local WOOD_LEFT = { 0.51, 0.33, 0.17 }
local WOOD_RIGHT = { 0.44, 0.28, 0.13 }
local WOOD_BACK = { 0.36, 0.22, 0.10 }

local RUBBER_FRONT = { 0.34, 0.25, 0.19 }
local RUBBER_LEFT = { 0.31, 0.22, 0.16 }
local RUBBER_RIGHT = { 0.28, 0.20, 0.14 }
local RUBBER_BACK = { 0.24, 0.17, 0.12 }

local HANDLE_TOP = { 0.62, 0.41, 0.21 }
local HANDLE_FRONT = { 0.56, 0.36, 0.19 }
local HANDLE_LEFT = { 0.49, 0.31, 0.16 }
local HANDLE_RIGHT = { 0.42, 0.27, 0.12 }
local HANDLE_BACK = { 0.35, 0.21, 0.09 }

local WOOD_EDGE = { 0.10, 0.05, 0.02 }
local HAND = { 1.00, 0.86, 0.18 }

local unpack = table.unpack or unpack

function M.clamp01(t)
	if t < 0 then return 0 end
	if t > 1 then return 1 end
	return t
end

function M.lerp(a, b, t)
	return a + (b - a) * t
end

-- Project a local 3D point.  y is up; screen y grows downward.
-- roll is a screen-space tilt around the stamp origin (the rubber pad).
function M.project(lx, ly, lz, ox, oy, scale, yaw, pitch, roll)
	local cy, sy = math.cos(yaw), math.sin(yaw)
	local cp, sp = math.cos(pitch), math.sin(pitch)
	local x1 = lx * cy + lz * sy
	local z1 = -lx * sy + lz * cy
	local y1 = ly * cp - z1 * sp
	local z2 = ly * sp + z1 * cp
	local persp = 1 / math.max(0.35, 1 + z2 * 0.0045)
	local sx = x1 * scale * persp
	local sy = -y1 * scale * persp
	roll = roll or 0
	if roll ~= 0 then
		local cr, sr = math.cos(roll), math.sin(roll)
		sx, sy = sx * cr - sy * sr, sx * sr + sy * cr
	end
	return ox + sx, oy + sy
end

function M.body_corners(ox, oy, scale, yaw, pitch, squash_y, roll)
	local hw, hh, hd = BODY_W * 0.5, BODY_H * squash_y, BODY_D * 0.5
	local rubber = RUBBER_H * squash_y
	local function P(lx, ly, lz)
		return { M.project(lx, ly, lz, ox, oy, scale, yaw, pitch, roll) }
	end
	return {
		ftl = P(-hw, rubber + hh, hd),
		ftr = P(hw, rubber + hh, hd),
		fbl = P(-hw, rubber, hd),
		fbr = P(hw, rubber, hd),
		btl = P(-hw, rubber + hh, -hd),
		btr = P(hw, rubber + hh, -hd),
		bbl = P(-hw, rubber, -hd),
		bbr = P(hw, rubber, -hd),
		rfl = P(-hw, 0, hd),
		rfr = P(hw, 0, hd),
		rbl = P(-hw, 0, -hd),
		rbr = P(hw, 0, -hd),
		hbl = P(-HANDLE_R, rubber + hh, HANDLE_R),
		hbr = P(HANDLE_R, rubber + hh, HANDLE_R),
		hfl = P(-HANDLE_R, rubber + hh + HANDLE_H, HANDLE_R),
		hfr = P(HANDLE_R, rubber + hh + HANDLE_H, HANDLE_R),
		hbb = P(-HANDLE_R, rubber + hh, -HANDLE_R),
		hbf = P(HANDLE_R, rubber + hh, -HANDLE_R),
		htb = P(-HANDLE_R, rubber + hh + HANDLE_H, -HANDLE_R),
		htf = P(HANDLE_R, rubber + hh + HANDLE_H, -HANDLE_R),
	}
end

function M.stamp_height_at_scale(scale, yaw, pitch, squash_y, roll)
	local c = M.body_corners(0, 0, scale, yaw, pitch, squash_y or 1, roll)
	local min_y, max_y = math.huge, -math.huge
	for _, pt in pairs(c) do
		min_y = math.min(min_y, pt[2])
		max_y = math.max(max_y, pt[2])
	end
	return max_y - min_y
end

function M.rubber_width_at_scale(scale, yaw, pitch, squash_y, roll)
	local c = M.body_corners(0, 0, scale, yaw, pitch, squash_y or 1, roll)
	return math.abs(c.rfr[1] - c.rfl[1])
end

function M.stamp_bounds_px(ox, oy, scale, yaw, pitch, squash_y, roll)
	local c = M.body_corners(ox, oy, scale, yaw, pitch, squash_y or 1, roll)
	local min_x, min_y, max_x, max_y = math.huge, math.huge, -math.huge, -math.huge
	for _, pt in pairs(c) do
		min_x = math.min(min_x, pt[1])
		min_y = math.min(min_y, pt[2])
		max_x = math.max(max_x, pt[1])
		max_y = math.max(max_y, pt[2])
	end
	return min_x, min_y, max_x, max_y
end

-- Place the stamp origin so the rubber pad centre sits on (cx, cy).
function M.anchor_to_contact(cx, cy, scale, yaw, pitch, squash_y, roll)
	local ox, oy = cx, cy
	squash_y = squash_y or 1
	for _ = 1, 8 do
		local c = M.body_corners(ox, oy, scale, yaw, pitch, squash_y, roll)
		local rbx = (c.rfl[1] + c.rfr[1] + c.rbl[1] + c.rbr[1]) * 0.25
		local rby = (c.rfl[2] + c.rfr[2] + c.rbl[2] + c.rbr[2]) * 0.25
		ox = ox + (cx - rbx)
		oy = oy + (cy - rby)
	end
	return ox, oy
end

function M.scale_for_slot(slot_w, yaw, pitch, roll)
	local target_rubber_w = slot_w * M.SLOT_WIDTH_FILL
	local lo, hi = 0.04, 4.0
	for _ = 1, 16 do
		local mid = (lo + hi) * 0.5
		if M.rubber_width_at_scale(mid, yaw, pitch, 1, roll) < target_rubber_w then
			lo = mid
		else
			hi = mid
		end
	end
	return (lo + hi) * 0.5
end

local function quad_fill(a, b, c, d, rgb, alpha)
	love.graphics.setColor(rgb[1], rgb[2], rgb[3], alpha)
	love.graphics.polygon("fill",
		a[1], a[2], b[1], b[2], c[1], c[2])
	love.graphics.polygon("fill",
		a[1], a[2], c[1], c[2], d[1], d[2])
end

-- Strokes a connected polyline through pts.  When closed, the first point is
-- repeated at the end so the loop encloses a face with a border on every
-- side; when open, the last segment back to pts[1] is omitted so a hidden
-- edge (e.g. the far back edge of a face) never gets stroked.
local function stroke_loop(pts, closed, alpha, width)
	love.graphics.setColor(0, 0, 0, alpha * 0.92)
	love.graphics.setLineWidth(width or 1.6)
	love.graphics.setLineJoin("miter")
	local coords = {}
	for _, p in ipairs(pts) do
		coords[#coords + 1] = p[1]
		coords[#coords + 1] = p[2]
	end
	if closed then
		coords[#coords + 1] = pts[1][1]
		coords[#coords + 1] = pts[1][2]
	end
	love.graphics.line(unpack(coords))
end

local function draw_hand(c, scale, alpha)
	local grip_x = (c.hfl[1] + c.hfr[1] + c.htb[1] + c.htf[1]) * 0.25
	local grip_y = (c.hfl[2] + c.hfr[2]) * 0.5
	local s = scale * 0.9

	love.graphics.setColor(HAND[1], HAND[2], HAND[3], alpha)
	love.graphics.ellipse("fill", grip_x + 2 * s, grip_y - 2 * s, 16 * s, 13 * s)
	-- Fingers wrapping the handle.
	for i = 0, 3 do
		local fx = grip_x - 10 * s + i * 7 * s
		local fy = grip_y + 6 * s + (i % 2) * 2 * s
		love.graphics.ellipse("fill", fx, fy, 5.5 * s, 8 * s)
	end
	love.graphics.setColor(WOOD_EDGE[1], WOOD_EDGE[2], WOOD_EDGE[3], alpha * 0.45)
	love.graphics.setLineWidth(1.4)
	love.graphics.ellipse("line", grip_x + 2 * s, grip_y - 2 * s, 16 * s, 13 * s)
end

-- Fills and strokes the wooden body + rubber pad for an already-projected
-- set of corners `c` (as returned by body_corners / debug_mesh).  Split out
-- so both the real draw pass and the debug tooling share one code path.
function M.draw_stamp_body(c, alpha)
	-- Multi-shaded 3D faces for wood body and rubber pad to enhance 3D perception.
	quad_fill(c.btl, c.btr, c.rbr, c.rbl, WOOD_BACK, alpha)
	quad_fill(c.btl, c.ftl, c.fbl, c.bbl, WOOD_LEFT, alpha)
	quad_fill(c.bbl, c.fbl, c.rfl, c.rbl, RUBBER_LEFT, alpha)
	quad_fill(c.ftl, c.ftr, c.btr, c.btl, WOOD_TOP, alpha)
	quad_fill(c.ftr, c.btr, c.bbr, c.fbr, WOOD_RIGHT, alpha)
	quad_fill(c.fbr, c.bbr, c.rbr, c.rfr, RUBBER_RIGHT, alpha)
	quad_fill(c.ftl, c.ftr, c.fbr, c.fbl, WOOD_FRONT, alpha)
	quad_fill(c.fbl, c.fbr, c.rfr, c.rfl, RUBBER_FRONT, alpha)

	-- Visible silhouettes and face borders. Each face is stroked as its own
	-- closed loop so every border shows up individually, including wood and
	-- rubber front/right/left faces. The top rim stays open so the hidden far/back
	-- edge is never stroked.
	stroke_loop({ c.btl, c.ftl, c.ftr, c.btr }, false, alpha)
	stroke_loop({ c.ftl, c.ftr, c.fbr, c.fbl }, true, alpha)
	stroke_loop({ c.fbl, c.fbr, c.rfr, c.rfl }, true, alpha)
	stroke_loop({ c.bbr, c.fbr, c.ftr, c.btr }, false, alpha)
	stroke_loop({ c.rbr, c.rfr, c.fbr, c.bbr }, false, alpha)
	stroke_loop({ c.btl, c.ftl, c.fbl, c.bbl }, true, alpha)
	stroke_loop({ c.bbl, c.fbl, c.rfl, c.rbl }, true, alpha)
end

function M.draw_shadow(cx, cy, slot_w, slot_h, approach, alpha)
	local w = slot_w * M.lerp(0.70, 1.0, approach)
	local h = slot_h * M.lerp(0.35, 0.85, approach)
	love.graphics.setColor(0, 0, 0, alpha * M.lerp(0.06, 0.28, approach))
	love.graphics.ellipse("fill", cx, cy + 2, w * 0.5, h * 0.5)
end

function M.draw_stamp_3d(ox, oy, scale, yaw, pitch, squash_y, alpha, roll)
	local c = M.body_corners(ox, oy, scale, yaw, pitch, squash_y, roll)

	M.draw_stamp_body(c, alpha)

	quad_fill(c.hbl, c.hbr, c.hfr, c.hfl, HANDLE_FRONT, alpha)
	quad_fill(c.hbr, c.hbf, c.htf, c.hfr, HANDLE_RIGHT, alpha)
	quad_fill(c.hfl, c.hfr, c.htf, c.htb, HANDLE_TOP, alpha)
	quad_fill(c.hbl, c.hfl, c.htb, c.hbb, HANDLE_LEFT, alpha)
	quad_fill(c.hbb, c.hbf, c.htf, c.htb, HANDLE_BACK, alpha)
	stroke_loop({ c.hbl, c.hbr, c.hfr, c.hfl }, true, alpha * 0.9, 1.2)
	stroke_loop({ c.hbr, c.hbf, c.htf, c.hfr }, true, alpha * 0.9, 1.2)
	stroke_loop({ c.hfl, c.hfr, c.htf, c.htb }, true, alpha * 0.9, 1.2)
	stroke_loop({ c.hbl, c.hfl, c.htb, c.hbb }, true, alpha * 0.9, 1.2)
	stroke_loop({ c.hbb, c.hbf, c.htf, c.htb }, true, alpha * 0.9, 1.2)

	draw_hand(c, scale, alpha)
end

function M.draw_type_imprint(art_entry, x, y, w, h, alpha)
	alpha = alpha or 1
	return perk_voucher.draw_stamp(art_entry, x, y, w, h, alpha * 0.96)
end

-- Returns the projected outline structure for a stamp posed at the given
-- params: named loops for the faces that get their own border (front, right,
-- and an open top rim), the raw projected corners, a screen-space bounding
-- box, and the back-plane edges that must never be stroked. Intended for
-- tests/tools; production drawing lives in draw_stamp_body/draw_stamp_3d.
function M.debug_mesh(ox, oy, scale, yaw, pitch, squash_y, roll)
	squash_y = squash_y or 1
	yaw = yaw or M.LANDING_YAW
	pitch = pitch or M.LANDING_PITCH
	roll = roll or M.LANDING_ROLL
	local c = M.body_corners(ox, oy, scale, yaw, pitch, squash_y, roll)

	local loops = {
		{ name = "top", closed = false, pts = { c.btl, c.ftl, c.ftr, c.btr } },
		{ name = "front", closed = true, pts = { c.ftl, c.ftr, c.fbr, c.fbl } },
		{ name = "rubber_front", closed = true, pts = { c.fbl, c.fbr, c.rfr, c.rfl } },
		{ name = "right", closed = false, pts = { c.bbr, c.fbr, c.ftr, c.btr } },
		{ name = "rubber_right", closed = false, pts = { c.rbr, c.rfr, c.fbr, c.bbr } },
		{ name = "left", closed = true, pts = { c.btl, c.ftl, c.fbl, c.bbl } },
		{ name = "rubber_left", closed = true, pts = { c.bbl, c.fbl, c.rfl, c.rbl } },
		{ name = "handle_front", closed = true, pts = { c.hbl, c.hbr, c.hfr, c.hfl } },
		{ name = "handle_right", closed = true, pts = { c.hbr, c.hbf, c.htf, c.hfr } },
		{ name = "handle_top", closed = true, pts = { c.hfl, c.hfr, c.htf, c.htb } },
		{ name = "handle_left", closed = true, pts = { c.hbl, c.hfl, c.htb, c.hbb } },
		{ name = "handle_back", closed = true, pts = { c.hbb, c.hbf, c.htf, c.htb } },
	}

	local hidden_back = {
		{ c.btl, c.btr },
		{ c.bbl, c.bbr },
		{ c.rbl, c.rbr },
		{ c.btr, c.bbr },
		{ c.bbr, c.rbr },
	}

	local min_x, min_y, max_x, max_y = math.huge, math.huge, -math.huge, -math.huge
	for _, pt in pairs(c) do
		min_x = math.min(min_x, pt[1])
		max_x = math.max(max_x, pt[1])
		min_y = math.min(min_y, pt[2])
		max_y = math.max(max_y, pt[2])
	end

	return {
		loops = loops,
		corners = c,
		bounds = { x = min_x, y = min_y, w = max_x - min_x, h = max_y - min_y },
		hidden_back = hidden_back,
	}
end

-- Runs the real draw path (draw_stamp_3d) at an explicit pose, for tests and
-- visual debugging outside of the strike animation.
function M.debug_draw_stamp(ox, oy, scale, yaw, pitch, squash_y, alpha, roll)
	squash_y = squash_y or 1
	alpha = alpha or 1
	yaw = yaw or M.LANDING_YAW
	pitch = pitch or M.LANDING_PITCH
	roll = roll or M.LANDING_ROLL
	M.draw_stamp_3d(ox, oy, scale, yaw, pitch, squash_y, alpha, roll)
end

-- Runs the real imprint draw path for tests/tools, without needing an
-- active strike animation.
function M.debug_draw_imprint(sprite_entry, x, y, w, h, alpha)
	M.draw_type_imprint(sprite_entry, x, y, w, h, alpha)
end

return M
