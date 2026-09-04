--[[
	word_game/ui/perk_stamp.lua - 3D rubber-stamp strike onto the vault.

	Stamps the row below Set/Hand with a vault-wide wooden block, then leaves a
	horizontal perk imprint on the side panel.
]]

local Layout = require("word_game.ui.layout")
local perk_cfg = require("word_game.config.perks")
local perk_model = require("word_game.model.perk")
local perk_voucher = require("word_game.ui.perk_voucher")
local stamp_grid = require("word_game.ui.stamp_grid")
local stamp_puff = require("word_game.ui.stamp_puff")
local state = require("word_game.model.state")
local widgets = require("word_game.ui.widgets")

local M = {}

local STRIKE_DUR = 1.05
local HOLD_DUR = 0.18
local RETRACT_DUR = 0.62
local IMPRINT_DUR = 0.55
local TOTAL_DUR = STRIKE_DUR + HOLD_DUR + RETRACT_DUR
local FRAME_DT = 1 / 36
local TOTAL_FRAMES = math.ceil(TOTAL_DUR / FRAME_DT)
local SLOT_WIDTH_FILL = 0.92
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
local imprints = {}
local pending_target_index
local make_anim_state

local function refresh_sidebar()
	if WORD_GAME and WORD_GAME.Sidebar and WORD_GAME.Sidebar.refresh then
		WORD_GAME.Sidebar:refresh()
	end
end

local function layout_stamp_count()
	local count = #imprints
	if pending_target_index then
		count = math.max(count, pending_target_index)
	elseif anim and not anim.impacted then
		count = count + 1
	end
	return math.max(1, count)
end

local function next_slot_index()
	return #imprints + 1
end

local function begin_stamp_anim(sprite_entry, perk_entry, debug)
	local target_index = next_slot_index()
	pending_target_index = target_index
	refresh_sidebar()
	anim = make_anim_state(sprite_entry, perk_entry, debug, target_index)
	pending_target_index = nil
end

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

local function node_world_xywh(node)
	if not node then return nil end
	local role = node.role
	local major = role and role.major
	local t = node.T or node.VT
	if not t then return nil end
	-- LayoutNodes store a local offset on `role`; `T`/`VT` can lag or stay in
	-- HUD-local space after a relayout. World = major origin + layout offset.
	if major and major.T and role.offset then
		return (major.T.x or 0) + (role.offset.x or 0),
			(major.T.y or 0) + (role.offset.y or 0),
			t.w or 0,
			t.h or 0
	end
	return t.x or 0, t.y or 0, t.w or 0, t.h or 0
end

local function node_rect_px(node)
	local x, y, w, h = node_world_xywh(node)
	if not x then return nil end
	local ts = tile_scale()
	return x * ts, y * ts, w * ts, h * ts
end

local function vault_width_px()
	return Layout.sidebar_width() * tile_scale()
end

local function stamp_panel_height_px()
	return stamp_grid.panel_height_px(nil, layout_stamp_count())
end

local function stamp_panel_rect_px(layout_count)
	layout_count = layout_count or layout_stamp_count()
	local row = G.VAULT_HUD and G.VAULT_HUD.find_node_by_id and G.VAULT_HUD:find_node_by_id("row_stamp_slot")
	local rx, ry, rw, rh = node_rect_px(row)
	if not rx then
		local vault = Layout.vault_rect()
		local ts = tile_scale()
		rx = vault.x * ts
		ry = (vault.y + 0.82) * ts
		rw = vault.w * ts
		rh = stamp_grid.panel_height_px(nil, layout_count)
	end
	local w = vault_width_px()
	local h = stamp_grid.panel_height_px(nil, layout_count)
	local box_h = math.max(rh or h, h)
	local x = rx + (rw - w) * 0.5
	local y = ry + (box_h - h) * 0.5
	return x, y, w, h, layout_count
end

local function stamp_cell_rect_px(index)
	index = index or next_slot_index()
	local count = math.max(index, layout_stamp_count())
	local panel_x, panel_y, panel_w, panel_h = stamp_panel_rect_px(count)
	return stamp_grid.cell_rect_px(panel_x, panel_y, panel_w, panel_h, index, count)
end

local function mouse_to_stamp_space(mx, my)
	local room = G and G.ROOM and G.ROOM.T
	if not room then return mx, my end
	local ts = tile_scale()
	local cx = room.w * ts * 0.5
	local cy = room.h * ts * 0.5
	local ox = -cx + (room.x or 0) * ts
	local oy = -cy + (room.y or 0) * ts
	local r = room.r or 0
	local x = mx - cx
	local y = my - cy
	if r ~= 0 then
		local cr, sr = math.cos(-r), math.sin(-r)
		x, y = x * cr - y * sr, x * sr + y * cr
	end
	return x - ox, y - oy
end

local function imprint_index_at(mx, my)
	if #imprints == 0 then return nil end
	local sx, sy = mouse_to_stamp_space(mx, my)
	for i = 1, #imprints do
		local x, y, w, h = stamp_cell_rect_px(i)
		if sx >= x and sx <= x + w and sy >= y and sy <= y + h then
			return i
		end
	end
	return nil
end

local function perk_popup_definition(entry)
	require("word_game.ui.perk_voucher_sprite")
	local w = (G.CARD_W or 1) * 0.9
	local h = w / (perk_cfg.VOUCHER_ASPECT or 2.3)
	local sprite = PerkVoucherSprite(0, 0, w, h, entry)
	return build_generic_options({
		contents = {
			{ n = G.UI.ROW, config = { align = "cm", padding = 0.06 }, nodes = {
				{ n = G.UI.OBJECT, config = { object = sprite, w = w, h = h } },
			}},
			{ n = G.UI.ROW, config = { align = "cm", padding = 0.04 }, nodes = {
				{ n = G.UI.TEXT, config = {
					text = entry.name or "Perk",
					scale = 0.42,
					colour = G.C.GOLD,
					shadow = true,
				}},
			}},
			{ n = G.UI.ROW, config = { align = "cm", padding = 0.06, maxw = 4.8 }, nodes = {
				{ n = G.UI.TEXT, config = {
					text = entry.desc or "",
					scale = 0.28,
					colour = G.C.UI.TEXT_LIGHT,
					shadow = true,
				}},
			}},
		},
	})
end

local function stamp_target_px(target_index)
	target_index = target_index or next_slot_index()
	local x, y, w, h = stamp_cell_rect_px(target_index)
	return x + w * 0.5, y + h * 0.5, x, y, w, h
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

local function copy_stamp(entry)
	return {
		id = entry.id,
		pos = { x = entry.pos.x, y = entry.pos.y },
	}
end

local function roll_stamp_sprite()
	local sprites = perk_cfg.STAMP_SPRITES
	if not sprites or #sprites == 0 then return nil end
	return copy_stamp(sprites[math.random(1, #sprites)])
end

local function resolve_stamp_sprite(sprite_entry)
	if sprite_entry then return copy_stamp(sprite_entry) end
	return roll_stamp_sprite()
end

local function resolve_stamp_perk(perk_entry)
	if perk_entry then return copy_perk(perk_entry) end
	if G.GAME and G.GAME.pending_stamp_perk then
		local pending = copy_perk(G.GAME.pending_stamp_perk)
		G.GAME.pending_stamp_perk = nil
		return pending
	end
	return perk_model.roll_stamp_perk()
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

local function quad_fill(a, b, c, d, rgb, alpha)
	love.graphics.setColor(rgb[1], rgb[2], rgb[3], alpha)
	love.graphics.polygon("fill",
		a[1], a[2], b[1], b[2], c[1], c[2])
	love.graphics.polygon("fill",
		a[1], a[2], c[1], c[2], d[1], d[2])
end

local function edge_line(a, b, alpha, width)
	love.graphics.setColor(0, 0, 0, alpha * 0.92)
	love.graphics.setLineWidth(width or 1.6)
	love.graphics.line(a[1], a[2], b[1], b[2])
end

local unpack = table.unpack or unpack

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

-- Fills and strokes the wooden body + rubber pad for an already-projected
-- set of corners `c` (as returned by body_corners / debug_mesh).  Split out
-- so both the real draw pass and the debug tooling share one code path.
local function draw_stamp_body(c, alpha)
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

local function draw_stamp_3d(ox, oy, scale, yaw, pitch, squash_y, alpha, roll)
	local c = body_corners(ox, oy, scale, yaw, pitch, squash_y, roll)

	draw_stamp_body(c, alpha)

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

local function draw_type_imprint(sprite_entry, x, y, w, h, alpha)
	alpha = alpha or 1
	perk_voucher.draw_stamp(sprite_entry, x, y, w, h, alpha * 0.96)
end

local function apply_imprint(sprite_entry, perk_entry)
	imprints[#imprints + 1] = {
		sprite = copy_stamp(sprite_entry),
		perk = copy_perk(perk_entry),
	}
	local perk = perk_cfg.by_id(perk_entry.id)
	if perk then
		perk_model.apply_choice(perk)
		state.add_perk(perk.id)
	end
	refresh_sidebar()
	return true
end

local function trigger_impact(frame)
	if frame.impacted then return end
	frame.impacted = true
	apply_imprint(frame.sprite_entry, frame.perk_entry)
	stamp_puff.spawn(frame.land_cx, frame.land_cy, frame.slot_w, frame.slot_h)
	if G.VIBRATION then
		G.VIBRATION = G.VIBRATION + 0.55
	end
	if play_sfx then
		play_sfx("stamp", 1.0, 0.9)
	end
end

make_anim_state = function(sprite_entry, perk_entry, debug, target_index)
	target_index = target_index or next_slot_index()
	local _, _, slot_x, slot_y, slot_w, slot_h = stamp_target_px(target_index)
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
		sprite_entry = sprite_entry,
		perk_entry = perk_entry,
		target_index = target_index,
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

local function begin_debug_anim(sprite_entry, perk_entry)
	begin_stamp_anim(sprite_entry, perk_entry, true)
end

function M.is_active()
	return anim ~= nil
end

function M.roll_stamp_sprite()
	return roll_stamp_sprite()
end

function M.roll_random_stamp()
	return roll_stamp_sprite()
end

function M.resolve_perk(perk_entry)
	return resolve_stamp_perk(perk_entry)
end

function M.queue(entry)
	if not entry or not entry.id then return false end
	if not G.GAME then return false end
	local resolved = perk_cfg.by_id(entry.id) or entry
	G.GAME.pending_stamp_perk = copy_perk(resolved)
	return true
end

function M.play(perk_entry, callback)
	if anim then return false end
	if G.STATE ~= G.STATES.TABLE_BOARD then return false end
	perk_entry = resolve_stamp_perk(perk_entry)
	if not perk_entry then return false end
	local sprite_entry = resolve_stamp_sprite()
	if not sprite_entry then return false end

	begin_stamp_anim(sprite_entry, perk_entry, false)
	if not anim then return false end
	anim.callback = callback
	if play_sfx then
		play_sfx("whoosh2", 0.85, 0.5)
	end
	return true
end

function M.demo_play()
	if G.STATE ~= G.STATES.TABLE_BOARD then return end
	if anim and not anim.debug and anim.t < TOTAL_DUR then return end

	anim = nil
	M.play()
end

function M.debug_step()
	if G.STATE ~= G.STATES.TABLE_BOARD then return end

	if anim and anim.finished then
		anim = nil
	end

	if not anim then
		local perk_entry = resolve_stamp_perk()
		local sprite_entry = resolve_stamp_sprite()
		if not perk_entry or not sprite_entry then return end
		begin_debug_anim(sprite_entry, perk_entry)
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

	stamp_puff.update(FRAME_DT)
end

function M.demo()
	M.debug_step()
end

function M.update(dt)
	dt = dt or (G and G.real_dt) or 0.016
	dt = math.min(0.05, dt)
	stamp_puff.update(dt)

	if not anim or anim.debug then
		if not anim and G.GAME and G.GAME.pending_stamp_perk then
			M.play()
		end
	end

	if not anim or anim.debug then return end
	anim.t = anim.t + dt

	if not anim.impacted and anim.t >= STRIKE_DUR then
		trigger_impact(anim)
	end

	if anim.t >= TOTAL_DUR then
		local done = anim
		anim = nil
		if done.callback then done.callback() end
		refresh_sidebar()
	end
end

function M.draw_pass()
	if G.STATE ~= G.STATES.TABLE_BOARD or not G.ROOM or not love.graphics then return end

	local prev_shader = love.graphics.getShader()
	local cr, cg, cb, ca = love.graphics.getColor()

	love.graphics.push()
	love.graphics.setShader()
	room_translate()

	local count = layout_stamp_count()
	for i, entry in ipairs(imprints) do
		local x, y, w, h = stamp_cell_rect_px(i)
		local alpha = 1
		if anim and i == #imprints and anim.impacted then
			local imprint_t = math.min(1, (anim.t - STRIKE_DUR) / IMPRINT_DUR)
			alpha = math.min(1, imprint_t * 2.2)
		end
		draw_type_imprint(entry.sprite, x, y, w, h, alpha)
	end

	stamp_puff.draw()

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

-- Returns the projected outline structure for a stamp posed at the given
-- params: named loops for the faces that get their own border (front, right,
-- and an open top rim), the raw projected corners, a screen-space bounding
-- box, and the back-plane edges that must never be stroked. Intended for
-- tests/tools; production drawing lives in draw_stamp_body/draw_stamp_3d.
function M.debug_mesh(ox, oy, scale, yaw, pitch, squash_y, roll)
	squash_y = squash_y or 1
	yaw = yaw or LANDING_YAW
	pitch = pitch or LANDING_PITCH
	roll = roll or LANDING_ROLL
	local c = body_corners(ox, oy, scale, yaw, pitch, squash_y, roll)

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
	yaw = yaw or LANDING_YAW
	pitch = pitch or LANDING_PITCH
	roll = roll or LANDING_ROLL
	draw_stamp_3d(ox, oy, scale, yaw, pitch, squash_y, alpha, roll)
end

-- Runs the real imprint draw path for tests/tools, without needing an
-- active strike animation.
function M.debug_draw_imprint(sprite_entry, x, y, w, h, alpha)
	draw_type_imprint(sprite_entry, x, y, w, h, alpha)
end

function M.debug_next_land_px()
	local target_index = next_slot_index()
	pending_target_index = target_index
	refresh_sidebar()
	local _, land_cy, _, slot_y = stamp_target_px(target_index)
	pending_target_index = nil
	return target_index, land_cy, slot_y
end

function M.clear_runtime()
	anim = nil
	imprints = {}
	pending_target_index = nil
	stamp_puff.reset()
end

function M.reset()
	M.clear_runtime()
	if G.VAULT_HUD and G.VAULT_HUD.remove then
		pcall(function() G.VAULT_HUD:remove() end)
	end
	G.VAULT_HUD = nil
end

function M.has_imprint()
	return #imprints > 0
end

function M.imprint_count()
	return #imprints
end

--- Screen-space cell rects for each landed imprint, top-to-bottom.
function M.imprint_cell_rects_px()
	local rects = {}
	for i = 1, #imprints do
		local x, y, w, h = stamp_cell_rect_px(i)
		rects[i] = { x = x, y = y, w = w, h = h }
	end
	return rects
end

function M.stack_count()
	return layout_stamp_count()
end

function M.current_imprint()
	local last = imprints[#imprints]
	return last and last.sprite
end

function M.current_imprint_perk()
	local last = imprints[#imprints]
	return last and last.perk
end

function M.current_imprints()
	return imprints
end

function M.show_perk_popup(perk_entry)
	if not perk_entry or not perk_entry.id then return false end
	local entry = perk_cfg.by_id(perk_entry.id) or perk_entry
	widgets.open(perk_popup_definition(copy_perk(entry)))
	return true
end

function M.consume_click(mx, my)
	if G.STATE ~= G.STATES.TABLE_BOARD then return false end
	if G.OVERLAY_MENU then return false end
	if anim and not anim.finished then return false end
	if #imprints == 0 then return false end

	local c = G.INPUT
	if not c or c.clicked.handled or not c.clicked.target then return false end
	if Card and getmetatable(c.clicked.target) == Card then return false end

	if not mx or not my then
		if not love or not love.mouse or not love.mouse.getPosition then return false end
		mx, my = love.mouse.getPosition()
	end
	local idx = imprint_index_at(mx, my)
	if not idx then return false end

	M.show_perk_popup(imprints[idx].perk)
	if play_sfx then play_sfx("card_slide1", 0.95, 0.5) end
	return true
end

function M.imprint_index_at_screen(mx, my)
	return imprint_index_at(mx, my)
end

-- Panel + per-slot cell rects for layout tests and tooling.
function M.debug_grid_layout(count)
	local panel_x, panel_y, panel_w = stamp_panel_rect_px()
	count = count or layout_stamp_count()
	return stamp_grid.layout(panel_x, panel_y, panel_w, count)
end

return M
