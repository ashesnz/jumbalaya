--[[
	word_game/ui/score_banner/draw.lua - Jumble score banner rendering.
]]

local Layout = require("word_game.ui.layout")
local felt_layout = require("word_game.ui.layout.felt")
local fonts = require("word_game.ui.score_banner.fonts")

local M = {}

local ComicBurst = require("word_game.ui.comic_burst")

local CHIP_BG = { 0.15, 0.38, 0.82, 1 }
local CHIP_BORDER = { 0.08, 0.22, 0.55, 1 }
local MULT_BG = { 0.85, 0.20, 0.25, 1 }
local MULT_BORDER = { 0.58, 0.10, 0.15, 1 }
local BOX_SHADOW = { 0.05, 0.08, 0.15, 0.35 }

local function clamp01(t)
	if t < 0 then return 0 end
	if t > 1 then return 1 end
	return t
end

local function ease_inout(t)
	t = clamp01(t)
	return t * t * (3 - 2 * t)
end

local BOSS_SWEEP_TIME = 0.45

local function hsv_to_rgb(h, s, v)
	local i = math.floor(h * 6) % 6
	local f = h * 6 - math.floor(h * 6)
	local p = v * (1 - s)
	local q = v * (1 - f * s)
	local t = v * (1 - (1 - f) * s)
	if i == 0 then return v, t, p end
	if i == 1 then return q, v, p end
	if i == 2 then return p, v, t end
	if i == 3 then return p, q, v end
	if i == 4 then return t, p, v end
	return v, p, q
end

local function room_translate()
	local room = G.ROOM
	if not room then return end
	local ts = G.TILESCALE * G.TILESIZE
	love.graphics.translate(room.T.w * ts * 0.5, room.T.h * ts * 0.5)
	love.graphics.rotate(room.T.r)
	love.graphics.translate(
		-room.T.w * ts * 0.5 + room.T.x * ts,
		-room.T.h * ts * 0.5 + room.T.y * ts
	)
end

local function draw_rolling_digit(cx, cy, from_val, to_val, roll, font, scale, col, box_w, box_h, is_float)
	local fh = font:getHeight() * scale
	local slot_h = box_h * 0.85
	local digit_y = cy - fh * 0.5

	local format_val = function(v)
		if is_float then
			return string.format("%.1f", v or 1.0)
		else
			return tostring(math.floor((v or 0) + 0.5))
		end
	end

	local from_str = format_val(from_val)
	local to_str = format_val(to_val)

	local psx, psy, psw, psh = nil, nil, nil, nil
	if love.graphics.transformPoint and love.graphics.intersectScissor and love.graphics.getScissor and love.graphics.setScissor then
		local x1, y1 = love.graphics.transformPoint(cx - box_w * 0.5, cy - box_h * 0.5)
		local x2, y2 = love.graphics.transformPoint(cx + box_w * 0.5, cy - box_h * 0.5)
		local x3, y3 = love.graphics.transformPoint(cx - box_w * 0.5, cy + box_h * 0.5)
		local x4, y4 = love.graphics.transformPoint(cx + box_w * 0.5, cy + box_h * 0.5)
		local sx = math.min(x1, x2, x3, x4)
		local sy = math.min(y1, y2, y3, y4)
		local sw = math.max(x1, x2, x3, x4) - sx
		local sh = math.max(y1, y2, y3, y4) - sy

		psx, psy, psw, psh = love.graphics.getScissor()
		love.graphics.intersectScissor(sx, sy, sw, sh)
	end

	local function print_str(str, y_off)
		local tw = font:getWidth(str) * scale
		local px = cx - tw * 0.5
		local py = digit_y + y_off
		if love.graphics.setColor then love.graphics.setColor(0, 0, 0, 0.6) end
		if love.graphics.print then love.graphics.print(str, px + 1.5, py + 1.5, 0, scale, scale) end
		if love.graphics.setColor then love.graphics.setColor(col[1], col[2], col[3], col[4] or 1) end
		if love.graphics.print then love.graphics.print(str, px, py, 0, scale, scale) end
	end

	if roll and roll.dur and roll.dur > 0 then
		local t = clamp01(roll.t / roll.dur)
		local inv = 1 - t
		local ease = 1 - inv * inv * inv
		print_str(from_str, -ease * slot_h)
		print_str(to_str, (1 - ease) * slot_h)
	else
		print_str(to_str, 0)
	end

	if love.graphics.setScissor then
		if psx then
			love.graphics.setScissor(psx, psy, psw, psh)
		else
			love.graphics.setScissor()
		end
	end
end

function M.draw(sb)
	if not G.GAME or not G.ROOM then return end
	if G.STATE ~= G.STATES.TABLE_BOARD then return end

	local dt = math.min(0.05, love.timer.getDelta())
	sb.update(dt)
	sb.decay_pulse(dt)

	-- The points x multi readout belongs to the normal HUD; when the vault
	-- sidebar is hidden for the boss sequence, it hides along with it. Only
	-- an explicit boss banner ("BOSS WORD") renders during the sequence.
	local hud_early = G.GAME and G.GAME.word_hud
	local mode_early = hud_early and hud_early.banner_mode or "normal"
	if mode_early ~= "boss_prep" and mode_early ~= "boss_word"
		and felt_layout.is_boss_sequence() then
		return
	end

	local ts = G.TILESCALE * G.TILESIZE
	local rect = Layout.banner_rect()
	local w = rect.w * ts
	local h = rect.h * ts
	local slant = rect.slant * ts
	local x = rect.x * ts
	local y = rect.y * ts

	local prev_font = love.graphics.getFont and love.graphics.getFont()
	local cr, cg, cb, ca = 1, 1, 1, 1
	if love.graphics.getColor then
		cr, cg, cb, ca = love.graphics.getColor()
	end
	local prev_shader = love.graphics.getShader and love.graphics.getShader()

	love.graphics.push()
	if love.graphics.setShader then love.graphics.setShader() end
	room_translate()

	local mid_y = y + h * 0.5
	if love.graphics.setLineStyle then love.graphics.setLineStyle("smooth") end
	if love.graphics.setLineJoin then love.graphics.setLineJoin("bevel") end

	local breathe = ease_inout(clamp01((math.sin((G.TIMERS.REAL or 0) * math.pi * 2 / 3) * 1.3 + 1) / 2))
	local pulse_s = 1 + sb.pulse_value() * 0.1
	local cx = x + w * 0.5
	local cy = mid_y

	love.graphics.push()
	love.graphics.translate(cx, cy)
	love.graphics.scale(pulse_s, pulse_s * (1 + breathe * 0.02))

	local layout = sb.calc_layout(w, h, slant)
	local box_size = layout.box_size
	local chip_cx = layout.chip_cx
	local mult_cx = layout.mult_cx
	local radius = layout.radius

	local hud = G.GAME and G.GAME.word_hud
	local banner_mode = hud and hud.banner_mode or "normal"
	if banner_mode == "boss_prep" or banner_mode == "boss_word" then
		local msg = (hud and hud.banner_message)
			or (banner_mode == "boss_prep" and "Boss Level!" or "BOSS WORD")

		-- Restart the banner sweep each time a new boss message appears.
		local sweep_key = banner_mode .. ":" .. tostring(msg)
		if sb.boss_sweep_key ~= sweep_key then
			sb.boss_sweep_key = sweep_key
			sb.boss_sweep_t = 0
		end
		sb.boss_sweep_t = (sb.boss_sweep_t or 0) + dt
		local sweep_u = clamp01(sb.boss_sweep_t / BOSS_SWEEP_TIME)
		local sweeping = sweep_u < 1
		-- Fast ease-out: rockets in from the side, crosses the word, brakes to
		-- a stop centred behind it.
		local eased = 1 - (1 - sweep_u) * (1 - sweep_u) * (1 - sweep_u)

		-- Bigger, bolder boss word.
		local msg_font_px = math.max(24, math.floor(h * 0.78))
		local msg_font = fonts.bubble_font(msg_font_px)
		love.graphics.setFont(msg_font)
		local msg_tw = msg_font:getWidth(msg)
		local msg_th = msg_font:getHeight()

		-- Banner image sweeping through from the side.
		local band_l, band_r = nil, nil
		local atlas = G.TEXTURE_ATLASES and G.TEXTURE_ATLASES.boss_banner
		if atlas and atlas.image and love.graphics.draw then
			local iw, ih = atlas.image:getDimensions()
			local img_h = h * 1.15
			local img_w = img_h * (iw / ih)
			if img_w < w * 1.3 then
				img_w = w * 1.3
				img_h = img_w * (ih / iw)
			end
			local start_x = -(w * 0.5 + img_w * 0.5 + 60)
			local bx = start_x + (0 - start_x) * eased
			band_l = bx - img_w * 0.5
			band_r = bx + img_w * 0.5
			love.graphics.setColor(1, 1, 1, 1)
			love.graphics.draw(atlas.image, band_l, -img_h * 0.5, 0, img_w / iw, img_h / ih)
		end

		love.graphics.setColor(0.04, 0.08, 0.16, 0.75)
		love.graphics.print(msg, -msg_tw * 0.5 + 2, -msg_th * 0.5 + 2)
		love.graphics.setColor(0.98, 0.92, 0.45, 1)
		love.graphics.print(msg, -msg_tw * 0.5, -msg_th * 0.5)

		-- While the banner is crossing the word, repaint the letters inside
		-- the banner band with a fast-cycling colour.
		if sweeping and band_l and love.graphics.transformPoint
			and love.graphics.intersectScissor and love.graphics.getScissor then
			local x1, y1 = love.graphics.transformPoint(band_l, -msg_th)
			local x2, y2 = love.graphics.transformPoint(band_r, msg_th)
			local psx, psy, psw, psh = love.graphics.getScissor()
			love.graphics.intersectScissor(
				math.min(x1, x2), math.min(y1, y2),
				math.abs(x2 - x1), math.abs(y2 - y1))
			local hr, hg, hb = hsv_to_rgb(((G.TIMERS.REAL or 0) * 1.8) % 1, 0.85, 1)
			love.graphics.setColor(hr, hg, hb, 1)
			love.graphics.print(msg, -msg_tw * 0.5, -msg_th * 0.5)
			if psx then
				love.graphics.setScissor(psx, psy, psw, psh)
			else
				love.graphics.setScissor()
			end
		end

		love.graphics.pop() -- inner transform (scale at line 137)
		love.graphics.pop() -- outer transform (room at line 124)
		if prev_shader and love.graphics.setShader then
			love.graphics.setShader(prev_shader)
		elseif love.graphics.setShader then
			love.graphics.setShader()
		end
		if prev_font and love.graphics.setFont then love.graphics.setFont(prev_font) end
		if love.graphics.setColor then love.graphics.setColor(cr, cg, cb, ca) end
		return
	end

	local pts_sx, pts_sy, pts_bounce_amt = sb.calc_bounce(sb.points_bounce)

	local cur_multi = sb.multi_roll
		and (sb.multi_roll.from + clamp01(sb.multi_roll.t / sb.multi_roll.dur) * (sb.multi_roll.to - sb.multi_roll.from))
		or (sb.jumble_multi or 1.0)
	local multi_growth = sb.get_multi_growth(cur_multi)
	local mult_sx, mult_sy, mult_bounce_amt = sb.calc_bounce(sb.multi_bounce)

	local pts_box_rot = sb.calc_box_rotation(sb.points_spin, sb.points_rot)
	local mult_box_rot = sb.calc_box_rotation(sb.multi_spin, sb.multi_rot)
	local pts_digit_rot = sb.calc_digit_rotation(sb.points_spin)
	local mult_digit_rot = sb.calc_digit_rotation(sb.multi_spin)

	local max_mult_scale = math.min(1.45, (h * 2.2) / box_size)
	local eff_mult_scale_x = math.min(max_mult_scale, mult_sx * multi_growth)
	local eff_mult_scale_y = math.min(max_mult_scale, mult_sy * multi_growth)
	local eff_pts_scale_x = math.min(max_mult_scale, pts_sx)
	local eff_pts_scale_y = math.min(max_mult_scale, pts_sy)

	local num_font = fonts.bubble_font(layout.num_font_px)
	local x_font = fonts.bubble_font(layout.x_font_px)

	if sb.points_burst then
		local burst_scale = math.max(box_size * 1.30, 42)
		love.graphics.push()
		love.graphics.translate(chip_cx, 0)
		love.graphics.scale(burst_scale, burst_scale * 0.85)
		ComicBurst.paint(sb.points_burst)
		love.graphics.pop()
	end

	if sb.multi_burst then
		local burst_scale = math.max(box_size * 1.30, 42)
		love.graphics.push()
		love.graphics.translate(mult_cx, 0)
		love.graphics.scale(burst_scale, burst_scale * 0.85)
		ComicBurst.paint(sb.multi_burst)
		love.graphics.pop()
	end

	love.graphics.push()
	love.graphics.translate(chip_cx, 0)
	love.graphics.scale(eff_pts_scale_x, eff_pts_scale_y)
	love.graphics.rotate(pts_box_rot)

	love.graphics.setColor(BOX_SHADOW)
	love.graphics.rectangle("fill", -box_size * 0.5 + 3, -box_size * 0.5 + 3, box_size, box_size, radius, radius)
	love.graphics.setColor(CHIP_BG)
	love.graphics.rectangle("fill", -box_size * 0.5, -box_size * 0.5, box_size, box_size, radius, radius)
	love.graphics.setLineWidth(math.max(3, box_size * 0.06))
	love.graphics.setColor(CHIP_BORDER)
	love.graphics.rectangle("line", -box_size * 0.5, -box_size * 0.5, box_size, box_size, radius, radius)

	love.graphics.setColor(1, 1, 1, 0.16 + pts_bounce_amt * 0.20)
	love.graphics.rectangle("fill", -box_size * 0.5 + 3, -box_size * 0.5 + 3, box_size - 6, box_size * 0.38, radius * 0.7, radius * 0.7)

	love.graphics.pop()

	love.graphics.push()
	love.graphics.translate(mult_cx, 0)
	love.graphics.scale(eff_mult_scale_x, eff_mult_scale_y)
	love.graphics.rotate(mult_box_rot)

	love.graphics.setColor(BOX_SHADOW)
	love.graphics.rectangle("fill", -box_size * 0.5 + 3, -box_size * 0.5 + 3, box_size, box_size, radius, radius)
	love.graphics.setColor(MULT_BG)
	love.graphics.rectangle("fill", -box_size * 0.5, -box_size * 0.5, box_size, box_size, radius, radius)
	love.graphics.setLineWidth(math.max(3, box_size * 0.06))
	love.graphics.setColor(MULT_BORDER)
	love.graphics.rectangle("line", -box_size * 0.5, -box_size * 0.5, box_size, box_size, radius, radius)

	love.graphics.setColor(1, 1, 1, 0.16 + mult_bounce_amt * 0.20)
	love.graphics.rectangle("fill", -box_size * 0.5 + 3, -box_size * 0.5 + 3, box_size - 6, box_size * 0.38, radius * 0.7, radius * 0.7)

	love.graphics.pop()

	love.graphics.push()
	love.graphics.translate(chip_cx, 0)
	love.graphics.scale(eff_pts_scale_x, eff_pts_scale_y)
	love.graphics.rotate(pts_digit_rot)

	love.graphics.setFont(num_font)
	fonts.set_score_shader(pts_bounce_amt, false)
	local from_p = sb.points_roll and sb.points_roll.from or sb.jumble_points or 0
	local to_p = sb.points_roll and sb.points_roll.to or sb.jumble_points or 0
	draw_rolling_digit(0, 0, from_p, to_p, sb.points_roll, num_font, 1, { 1, 1, 1, 1 }, box_size, box_size, false)
	fonts.reset_score_shader()

	love.graphics.pop()

	love.graphics.push()
	love.graphics.translate(mult_cx, 0)
	love.graphics.scale(eff_mult_scale_x, eff_mult_scale_y)
	love.graphics.rotate(mult_digit_rot)

	love.graphics.setFont(num_font)
	fonts.set_score_shader(mult_bounce_amt, true)
	local from_m = sb.multi_roll and sb.multi_roll.from or sb.jumble_multi or 1.0
	local to_m = sb.multi_roll and sb.multi_roll.to or sb.jumble_multi or 1.0
	draw_rolling_digit(0, 0, from_m, to_m, sb.multi_roll, num_font, 1, { 1, 1, 1, 1 }, box_size, box_size, true)
	fonts.reset_score_shader()

	love.graphics.pop()

	love.graphics.setFont(x_font)
	local x_str = "X"
	local x_tw = layout.x_tw
	local x_th = x_font:getHeight()
	love.graphics.setColor(0.10, 0.12, 0.20, 0.85)
	love.graphics.print(x_str, -x_tw * 0.5 + 2, -x_th * 0.5 + 2)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.print(x_str, -x_tw * 0.5, -x_th * 0.5)

	love.graphics.pop()

	if not sb.hide_points_to_get and not felt_layout.is_boss_sequence() then
		local to_get_val = sb.points_to_get or (G.GAME and G.GAME.word_round and G.GAME.word_round.target) or 20
		local to_get_txt = tostring(to_get_val) .. " Points to get"
		local to_get_font_px = math.max(16, math.floor(h * 0.45))
		local to_get_font = fonts.title_font(to_get_font_px)
		love.graphics.setFont(to_get_font)
		local to_get_tw = to_get_font:getWidth(to_get_txt)
		local to_get_th = to_get_font:getHeight()

		local to_get_cx, to_get_cy = sb.calc_points_to_get_pos(cx, ts)
		local to_get_tx = to_get_cx - to_get_tw * 0.5
		local to_get_ty = to_get_cy - to_get_th * 0.5

		love.graphics.setColor(0.04, 0.08, 0.16, 0.75)
		love.graphics.print(to_get_txt, to_get_tx + 1.5, to_get_ty + 1.5)
		love.graphics.setColor(0.98, 0.96, 0.90, 1)
		love.graphics.print(to_get_txt, to_get_tx, to_get_ty)
	end

	love.graphics.pop()
	if prev_shader and love.graphics.setShader then
		love.graphics.setShader(prev_shader)
	elseif love.graphics.setShader then
		love.graphics.setShader()
	end
	if prev_font and love.graphics.setFont then love.graphics.setFont(prev_font) end
	if love.graphics.setColor then love.graphics.setColor(cr, cg, cb, ca) end
end

return M
