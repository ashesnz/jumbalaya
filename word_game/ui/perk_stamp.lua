--[[
	word_game/ui/perk_stamp.lua - 3D rubber-stamp strike onto the vault.

	Stamps the row below Set/Hand with a vault-wide wooden block, then leaves a
	horizontal perk imprint on the side panel.
]]

local Layout = require("word_game.ui.layout")
local perk_cfg = require("word_game.config.perks")
local perk_model = require("word_game.model.perk")

local M = {}

local STRIKE_DUR = 1.05
local HOLD_DUR = 0.18
local RETRACT_DUR = 0.62
local IMPRINT_DUR = 0.55
local TOTAL_DUR = STRIKE_DUR + HOLD_DUR + RETRACT_DUR
local FRAME_DT = 1 / 36
local TOTAL_FRAMES = math.ceil(TOTAL_DUR / FRAME_DT)
local IMPRINT_H_PX = 50
local SLOT_WIDTH_FILL = 1.0
local START_SCALE_MUL = 2.4
-- 3/4 view: long axis stays horizontal so the block matches the vault row.
-- Roll is the slight diagonal tilt of a hand coming down from above-right.
local LANDING_YAW = 0.32
local LANDING_PITCH = 0.26
local LANDING_ROLL = -0.06
local START_YAW = 0.50
local START_PITCH = 0.48
local START_ROLL = -0.22

-- Local-space millimetres of the wooden block (x right, y up, z toward camera).
local BODY_W = 96
local BODY_H = 22
local BODY_D = 42
local RUBBER_H = 7
local HANDLE_R = 7
local HANDLE_H = 22

local anim
local imprint
local demo_index = 1

local WOOD_TOP = { 0.72, 0.48, 0.26 }
local WOOD_FRONT = { 0.52, 0.32, 0.16 }
local WOOD_SIDE = { 0.36, 0.20, 0.10 }
local WOOD_EDGE = { 0.10, 0.05, 0.02 }
local RUBBER = { 0.22, 0.10, 0.08 }
local HANDLE = { 0.42, 0.24, 0.12 }
local HAND = { 1.00, 0.86, 0.18 }

local function clamp01(t)
	if t < 0 then return 0 end
	if t > 1 then return 1 end
	return t
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

local function ease_in_cubic(t)
	t = clamp01(t)
	return t * t * t
end

local function ease_in_quad(t)
	t = clamp01(t)
	return t * t
end

local function ease_out_quad(t)
	t = clamp01(t)
	local u = 1 - t
	return 1 - u * u
end

local function imprint_bounce(t)
	t = clamp01(t)
	if t < 0.55 then
		return 0.22 + 0.98 * ease_out_quad(t / 0.55)
	end
	return 1.20 - 0.20 * ease_out_quad((t - 0.55) / 0.45)
end

local function room_translate()
	local room = G and G.ROOM
	if not room or not love or not love.graphics then return end
	local ts = (G.TILESCALE or 1) * (G.TILESIZE or 1)
	love.graphics.translate(room.T.w * ts * 0.5, room.T.h * ts * 0.5)
	love.graphics.rotate(room.T.r or 0)
	love.graphics.translate(
		-room.T.w * ts * 0.5 + (room.T.x or 0) * ts,
		-room.T.h * ts * 0.5 + (room.T.y or 0) * ts
	)
end

local function tile_scale()
	return (G.TILESCALE or 1) * (G.TILESIZE or 1)
end

local function node_rect_px(node)
	if not node then return nil end
	local t = node.VT or node.T
	if not t then return nil end
	local ts = tile_scale()
	return t.x * ts, t.y * ts, (t.w or 0) * ts, (t.h or 0) * ts
end

local function vault_width_px()
	return Layout.sidebar_width() * tile_scale()
end

local function stamp_slot_rect_px()
	local row = G.VAULT_HUD and G.VAULT_HUD:find_node_by_id("row_stamp_slot")
	local rx, ry, rw, rh = node_rect_px(row)
	if not rx then
		local vault = Layout.vault_rect()
		local ts = tile_scale()
		rx = vault.x * ts
		ry = (vault.y + 0.82) * ts
		rw = vault.w * ts
		rh = IMPRINT_H_PX
	end
	local w = vault_width_px()
	local x = rx + (rw - w) * 0.5
	local y = ry + (rh - IMPRINT_H_PX) * 0.5
	return x, y, w, IMPRINT_H_PX
end

local function stamp_target_px()
	local x, y, w, h = stamp_slot_rect_px()
	return x + w * 0.5, y + h * 0.5, x, y, w, h
end

-- Project a local 3D point.  y is up; screen y grows downward.
-- roll is a screen-space tilt around the stamp origin (the rubber pad).
local function project(lx, ly, lz, ox, oy, scale, yaw, pitch, roll)
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

local function body_corners(ox, oy, scale, yaw, pitch, squash_y, roll)
	local hw, hh, hd = BODY_W * 0.5, BODY_H * squash_y, BODY_D * 0.5
	local rubber = RUBBER_H * squash_y
	local function P(lx, ly, lz)
		return { project(lx, ly, lz, ox, oy, scale, yaw, pitch, roll) }
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

local function stamp_height_at_scale(scale, yaw, pitch, squash_y, roll)
	local c = body_corners(0, 0, scale, yaw, pitch, squash_y or 1, roll)
	local min_y, max_y = math.huge, -math.huge
	for _, pt in pairs(c) do
		min_y = math.min(min_y, pt[2])
		max_y = math.max(max_y, pt[2])
	end
	return max_y - min_y
end

local function rubber_width_at_scale(scale, yaw, pitch, squash_y, roll)
	local c = body_corners(0, 0, scale, yaw, pitch, squash_y or 1, roll)
	return math.abs(c.rfr[1] - c.rfl[1])
end

local function stamp_bounds_px(ox, oy, scale, yaw, pitch, squash_y, roll)
	local c = body_corners(ox, oy, scale, yaw, pitch, squash_y or 1, roll)
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
local function anchor_to_contact(cx, cy, scale, yaw, pitch, squash_y, roll)
	local ox, oy = cx, cy
	squash_y = squash_y or 1
	for _ = 1, 8 do
		local c = body_corners(ox, oy, scale, yaw, pitch, squash_y, roll)
		local rbx = (c.rfl[1] + c.rfr[1] + c.rbl[1] + c.rbr[1]) * 0.25
		local rby = (c.rfl[2] + c.rfr[2] + c.rbl[2] + c.rbr[2]) * 0.25
		ox = ox + (cx - rbx)
		oy = oy + (cy - rby)
	end
	return ox, oy
end

local function screen_top_px()
	local room = G.ROOM and G.ROOM.T
	return ((room and room.y) or 0) * tile_scale() + 10
end

local function scale_for_slot(slot_w, yaw, pitch, roll)
	local target_rubber_w = slot_w * SLOT_WIDTH_FILL
	local lo, hi = 0.04, 4.0
	for _ = 1, 16 do
		local mid = (lo + hi) * 0.5
		if rubber_width_at_scale(mid, yaw, pitch, 1, roll) < target_rubber_w then
			lo = mid
		else
			hi = mid
		end
	end
	return (lo + hi) * 0.5
end

local function perk_quad(entry)
	local atlas = G.TEXTURE_ATLASES and G.TEXTURE_ATLASES.Perk
	if not atlas or not atlas.image or not entry or not entry.pos then return end
	local pw, ph = atlas.px or 71, atlas.py or 95
	local iw, ih = atlas.image:getDimensions()
	return atlas.image, love.graphics.newQuad(
		entry.pos.x * pw, entry.pos.y * ph, pw, ph, iw, ih), pw, ph
end

local function quad_fill(a, b, c, d, rgb, alpha)
	love.graphics.setColor(rgb[1], rgb[2], rgb[3], alpha)
	love.graphics.polygon("fill",
		a[1], a[2], b[1], b[2], c[1], c[2])
	love.graphics.polygon("fill",
		a[1], a[2], c[1], c[2], d[1], d[2])
end

local function edge_line(a, b, alpha, width)
	love.graphics.setColor(WOOD_EDGE[1], WOOD_EDGE[2], WOOD_EDGE[3], alpha * 0.85)
	love.graphics.setLineWidth(width or 1.6)
	love.graphics.line(a[1], a[2], b[1], b[2])
end

local function shade(rgb, mul)
	return { rgb[1] * mul, rgb[2] * mul, rgb[3] * mul }
end

local function stamp_pose(t, anim_state)
	local squash_y = 1
	local phase = "strike"
	local approach

	if t < STRIKE_DUR then
		phase = "strike"
		approach = ease_in_cubic(t / STRIKE_DUR)
	elseif t < STRIKE_DUR + HOLD_DUR then
		phase = "hold"
		approach = 1
		local hold = 1 - (t - STRIKE_DUR) / HOLD_DUR
		squash_y = 1 - 0.12 * hold
	else
		phase = "retract"
		local u = ease_out_quad((t - STRIKE_DUR - HOLD_DUR) / RETRACT_DUR)
		approach = 1 - u
	end

	-- Contact point travels from above the screen onto the row; origin is
	-- solved so the rubber pad stays glued to that point at every frame.
	local cx = lerp(anim_state.start_cx, anim_state.land_cx, approach)
	local cy = lerp(anim_state.start_cy, anim_state.land_cy, approach)
	local yaw = lerp(START_YAW, LANDING_YAW, approach)
	local pitch = lerp(START_PITCH, LANDING_PITCH, approach)
	local roll = lerp(START_ROLL, LANDING_ROLL, approach)
	-- Shrink as it recedes toward the panel (near-camera → far-table).
	local scale = lerp(anim_state.start_scale, anim_state.land_scale, ease_out_quad(approach))
	local ox, oy = anchor_to_contact(cx, cy, scale, yaw, pitch, squash_y, roll)
	return ox, oy, scale, yaw, pitch, roll, squash_y, phase, approach
end

local function draw_shadow(cx, cy, slot_w, slot_h, approach, alpha)
	local w = slot_w * lerp(0.70, 1.0, approach)
	local h = slot_h * lerp(0.35, 0.85, approach)
	love.graphics.setColor(0, 0, 0, alpha * lerp(0.06, 0.28, approach))
	love.graphics.ellipse("fill", cx, cy + 2, w * 0.5, h * 0.5)
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

local function draw_stamp_3d(ox, oy, scale, yaw, pitch, squash_y, alpha, roll)
	local c = body_corners(ox, oy, scale, yaw, pitch, squash_y, roll)

	-- Back-to-front fills.  Front and right side are drawn last so they stay visible.
	quad_fill(c.btl, c.btr, c.bbr, c.bbl, WOOD_TOP, alpha)
	quad_fill(c.btl, c.ftl, c.fbl, c.bbl, WOOD_SIDE, alpha)
	quad_fill(c.fbr, c.bbr, c.rbr, c.rfr, shade(RUBBER, 0.75), alpha)
	quad_fill(c.fbl, c.fbr, c.rfr, c.rfl, RUBBER, alpha)
	quad_fill(c.ftl, c.ftr, c.btr, c.btl, WOOD_TOP, alpha)
	quad_fill(c.ftr, c.btr, c.bbr, c.fbr, shade(WOOD_SIDE, 0.9), alpha)
	quad_fill(c.ftl, c.ftr, c.fbr, c.fbl, WOOD_FRONT, alpha)

	-- Exterior outlines only — top rim plus the two vertical front edges.
	edge_line(c.ftl, c.ftr, alpha)
	edge_line(c.ftl, c.btl, alpha)
	edge_line(c.ftr, c.btr, alpha)
	edge_line(c.ftl, c.fbl, alpha)
	edge_line(c.ftr, c.fbr, alpha)

	quad_fill(c.hbl, c.hbr, c.hfr, c.hfl, HANDLE, alpha)
	quad_fill(c.hbr, c.hbf, c.htf, c.hfr, shade(HANDLE, 0.8), alpha)
	quad_fill(c.hfl, c.hfr, c.htf, c.htb, shade(HANDLE, 1.15), alpha)
	edge_line(c.hbl, c.hbr, alpha, 1.2)
	edge_line(c.hbr, c.hfr, alpha, 1.2)
	edge_line(c.hfr, c.hfl, alpha, 1.2)
	edge_line(c.hfl, c.hbl, alpha, 1.2)

	draw_hand(c, scale, alpha)
end

local function copy_perk(entry)
	return {
		id = entry.id,
		name = entry.name,
		desc = entry.desc,
		pos = { x = entry.pos.x, y = entry.pos.y },
		token_cost = entry.token_cost,
	}
end

local function draw_type_imprint(entry, x, y, w, h, alpha)
	alpha = alpha or 1
	love.graphics.setColor(0.14, 0.08, 0.05, alpha * 0.42)
	love.graphics.rectangle("fill", x, y, w, h, 3, 3)

	local img, quad, pw, ph = perk_quad(entry)
	if img and quad then
		local pad = 5
		local draw_w = math.max(1, w - pad * 2)
		local draw_h = math.max(1, h - pad * 2)
		love.graphics.setColor(1, 1, 1, alpha * 0.92)
		love.graphics.draw(img, quad, x + pad, y + pad, 0, draw_w / pw, draw_h / ph)
	end

	love.graphics.setColor(WOOD_EDGE[1], WOOD_EDGE[2], WOOD_EDGE[3], alpha * 0.75)
	love.graphics.setLineWidth(2)
	love.graphics.line(x, y, x + w, y)
	love.graphics.line(x, y + h, x + w, y + h)
end

local function apply_imprint(entry)
	imprint = { entry = copy_perk(entry) }
	perk_model.apply_choice(entry)
end

local function trigger_impact(frame)
	if frame.impacted then return end
	frame.impacted = true
	apply_imprint(frame.entry)
	if G.VIBRATION then
		G.VIBRATION = G.VIBRATION + 0.55
	end
	if play_sfx then
		play_sfx("multhit2", 1.0, 0.8)
	end
end

local function make_anim_state(entry, debug)
	local _, _, slot_x, slot_y, slot_w, slot_h = stamp_target_px()
	local land_cx = slot_x + slot_w * 0.5
	local land_cy = slot_y + slot_h * 0.5
	local land_scale = scale_for_slot(slot_w, LANDING_YAW, LANDING_PITCH, LANDING_ROLL)
	local start_scale = land_scale * START_SCALE_MUL

	local start_cx = land_cx + slot_w * 0.16
	local start_cy = land_cy
	local top = screen_top_px()
	for _ = 1, 8 do
		local ox, oy = anchor_to_contact(
			start_cx, start_cy, start_scale, START_YAW, START_PITCH, 1, START_ROLL)
		local _, _, _, max_y = stamp_bounds_px(
			ox, oy, start_scale, START_YAW, START_PITCH, 1, START_ROLL)
		start_cy = start_cy + ((top - 28) - max_y)
	end

	return {
		entry = entry,
		t = 0,
		frame = 0,
		slot_x = slot_x,
		slot_y = slot_y,
		slot_w = slot_w,
		slot_h = slot_h,
		land_cx = land_cx,
		land_cy = land_cy,
		start_cx = start_cx,
		start_cy = start_cy,
		start_scale = start_scale,
		land_scale = land_scale,
		target_scale = land_scale,
		impacted = false,
		finished = false,
		debug = debug,
	}
end

local function begin_debug_anim(entry)
	imprint = nil
	anim = make_anim_state(entry, true)
end

function M.is_active()
	return anim ~= nil
end

function M.play(entry, callback)
	if anim or not entry then return false end
	if G.STATE ~= G.STATES.TABLE_BOARD then return false end

	imprint = nil
	anim = make_anim_state(copy_perk(entry), false)
	anim.callback = callback
	if play_sfx then
		play_sfx("whoosh2", 0.85, 0.5)
	end
	return true
end

function M.debug_step()
	if G.STATE ~= G.STATES.TABLE_BOARD then return end

	if anim and anim.finished then
		anim = nil
	end

	if not anim then
		local pool = perk_cfg.POOL
		if #pool == 0 then return end
		demo_index = (demo_index - 1) % #pool + 1
		begin_debug_anim(copy_perk(pool[demo_index]))
		if play_sfx then
			play_sfx("whoosh2", 0.85, 0.5)
		end
		return
	end

	anim.frame = anim.frame + 1
	anim.t = math.min(TOTAL_DUR, anim.frame * FRAME_DT)

	if not anim.impacted and anim.t >= STRIKE_DUR then
		trigger_impact(anim)
	end

	if anim.frame >= TOTAL_FRAMES then
		anim.t = TOTAL_DUR
		anim.finished = true
	end
end

function M.demo()
	M.debug_step()
end

function M.update(dt)
	if not anim or anim.debug then return end
	dt = dt or (G and G.real_dt) or 0.016
	dt = math.min(0.05, dt)
	anim.t = anim.t + dt

	if not anim.impacted and anim.t >= STRIKE_DUR then
		trigger_impact(anim)
	end

	if anim.t >= TOTAL_DUR then
		local done = anim
		anim = nil
		if done.callback then done.callback() end
		if WORD_GAME and WORD_GAME.Sidebar then
			WORD_GAME.Sidebar:refresh()
		end
	end
end

function M.draw_pass()
	if G.STATE ~= G.STATES.TABLE_BOARD or not G.ROOM or not love.graphics then return end

	local prev_shader = love.graphics.getShader()
	local cr, cg, cb, ca = love.graphics.getColor()

	love.graphics.push()
	love.graphics.setShader()
	room_translate()

	if imprint and imprint.entry then
		local x, y, w, h = stamp_slot_rect_px()
		local alpha = 1
		if anim and anim.impacted then
			local imprint_t = math.min(1, (anim.t - STRIKE_DUR) / IMPRINT_DUR)
			alpha = math.min(1, imprint_t * 2.2)
		end
		draw_type_imprint(imprint.entry, x, y, w, h, alpha)
	end

	if anim then
		local frame = anim
		local x, y, scale, yaw, pitch, roll, squash_y, phase, approach = stamp_pose(frame.t, frame)
		local stamp_alpha = 1
		if phase == "retract" then
			stamp_alpha = clamp01(1 - (frame.t - STRIKE_DUR - HOLD_DUR) / RETRACT_DUR)
		end

		if stamp_alpha > 0.02 then
			draw_shadow(frame.land_cx, frame.land_cy, frame.slot_w, frame.slot_h, approach, stamp_alpha)
			draw_stamp_3d(x, y, scale, yaw, pitch, squash_y, stamp_alpha, roll)
		end
	end

	love.graphics.pop()
	if prev_shader then
		love.graphics.setShader(prev_shader)
	else
		love.graphics.setShader()
	end
	love.graphics.setColor(cr, cg, cb, ca)
end

function M.reset()
	anim = nil
	imprint = nil
end

return M
