--[[
	word_game/ui/boss_word_announce.lua - Boss countdown ribbons below the timer.

	Boss word: sweeps left-to-right at "Are you ready?"
	Theme: sweeps right-to-left at "1", sits below boss word, banner rotated 180°.
]]

local Layout = require("word_game.ui.layout")
local fonts = require("word_game.ui.score_banner.fonts")
local word_feedback = require("word_game.ui.word_feedback")

local M = {}

local SWEEP_TIME = 0.55
local SIZE_SCALE = 0.5
local TIMER_GAP_PX = 45
local BANNER_STACK_GAP_PX = 10
local REF_TILE_PX = 73

local boss_banner = nil
local theme_banner = nil

local function clamp01(t)
	if t < 0 then return 0 end
	if t > 1 then return 1 end
	return t
end

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

local function pixels_per_tile()
	local px = (G.TILESIZE or 1) * (G.TILESCALE or 1)
	return px > 0 and px or REF_TILE_PX
end

local function px_to_tiles(px)
	return px / pixels_per_tile()
end

local function gap_below_timer_tiles()
	local scale = pixels_per_tile() / REF_TILE_PX
	return px_to_tiles(TIMER_GAP_PX * scale)
end

local function stack_gap_tiles()
	local scale = pixels_per_tile() / REF_TILE_PX
	return px_to_tiles(BANNER_STACK_GAP_PX * scale)
end

local function boss_layout_tiles()
	local timer = Layout.timeline_rect()
	local banner = Layout.banner_rect()
	if not timer or not banner then return nil end
	local hand = word_feedback.hand_dealt_metrics()
	local banner_h = banner.h * SIZE_SCALE
	local ornament_pad = banner_h * 0.075
	local gap = gap_below_timer_tiles() + ornament_pad
	local top = timer.y + timer.h + gap
	local cx = hand and hand.cx or (timer.x + timer.w * 0.5)
	return {
		cx = cx,
		cy = top + banner_h * 0.5,
		w = (hand and hand.gap_w or banner.w) * SIZE_SCALE,
		h = banner_h,
	}
end

local function layout_tiles(slot)
	local boss = boss_layout_tiles()
	if not boss then return nil end
	if slot == "boss" then
		return boss
	end
	local stack_gap = stack_gap_tiles()
	return {
		cx = boss.cx,
		cy = boss.cy + boss.h * 0.5 + stack_gap + boss.h * 0.5,
		w = boss.w,
		h = boss.h,
	}
end

local function layout_pixels(slot)
	local tiles = layout_tiles(slot)
	if not tiles then return nil end
	local ts = G.TILESCALE * G.TILESIZE
	return {
		cx = tiles.cx * ts,
		cy = tiles.cy * ts,
		w = tiles.w * ts,
		h = tiles.h * ts,
	}
end

local function new_banner(text, opts)
	opts = opts or {}
	return {
		text = text,
		t = 0,
		sweep_time = SWEEP_TIME,
		direction = opts.direction or "ltr",
		rotate = opts.rotate or false,
		slot = opts.slot or "boss",
	}
end

local function advance_banner(banner, dt)
	if not banner then return end
	if banner.t < banner.sweep_time then
		banner.t = math.min(banner.sweep_time, banner.t + dt)
	end
end

function M.is_active()
	return boss_banner ~= nil or theme_banner ~= nil
end

function M.play_boss(text)
	text = text or "BOSS WORD"
	if boss_banner and boss_banner.text == text then return end
	boss_banner = new_banner(text, { direction = "ltr", slot = "boss" })
	if play_sfx then
		play_sfx("timpani", 0.95, 0.82)
	end
end

function M.play_theme(text)
	text = text or "Garden Theme"
	if theme_banner and theme_banner.text == text then return end
	theme_banner = new_banner(text, { direction = "rtl", rotate = true, slot = "theme" })
end

-- Back-compat with score banner facade.
function M.play(text)
	M.play_boss(text)
end

function M.clear()
	boss_banner = nil
	theme_banner = nil
end

function M.update(dt)
	advance_banner(boss_banner, dt)
	advance_banner(theme_banner, dt)
end

local function draw_professional_text(msg, msg_tw, msg_th, alpha)
	local tx = -msg_tw * 0.5
	local ty = -msg_th * 0.5
	love.graphics.setColor(0.05, 0.08, 0.14, 0.55 * alpha)
	love.graphics.print(msg, tx + 1, ty + 2)
	love.graphics.setColor(0.96, 0.93, 0.86, alpha)
	love.graphics.print(msg, tx, ty)
	love.graphics.setColor(1, 1, 1, 0.22 * alpha)
	love.graphics.print(msg, tx, ty - 1)
end

local function draw_banner(banner)
	local rect = layout_pixels(banner.slot)
	if not rect then return end

	local sweep_u = clamp01(banner.t / banner.sweep_time)
	local eased = 1 - (1 - sweep_u) * (1 - sweep_u) * (1 - sweep_u)
	local sweeping = sweep_u < 1
	local from_right = banner.direction == "rtl"

	local msg = banner.text
	local msg_font_px = math.max(14, math.floor(rect.h * 0.58))
	local msg_font = fonts.title_font(msg_font_px)
	local msg_tw = msg_font:getWidth(msg)
	local msg_th = msg_font:getHeight()

	love.graphics.push()
	love.graphics.translate(rect.cx, rect.cy)

	local band_l, band_r, band_cx = nil, nil, nil
	local atlas = G.TEXTURE_ATLASES and G.TEXTURE_ATLASES.boss_banner
	if atlas and atlas.image and love.graphics.draw then
		local iw, ih = atlas.image:getDimensions()
		local img_h = rect.h * 1.15
		local img_w = img_h * (iw / ih)
		if img_w < rect.w * 1.3 then
			img_w = rect.w * 1.3
			img_h = img_w * (ih / iw)
		end
		local offscreen = rect.w * 0.5 + img_w * 0.5 + 60
		local start_x = from_right and offscreen or -offscreen
		band_cx = start_x + (0 - start_x) * eased
		band_l = band_cx - img_w * 0.5
		band_r = band_cx + img_w * 0.5
		love.graphics.setColor(1, 1, 1, 1)
		if banner.rotate then
			love.graphics.draw(
				atlas.image, band_cx, 0, math.pi,
				img_w / iw, img_h / ih, iw * 0.5, ih * 0.5
			)
		else
			love.graphics.draw(atlas.image, band_l, -img_h * 0.5, 0, img_w / iw, img_h / ih)
		end
	end

	love.graphics.setFont(msg_font)
	draw_professional_text(msg, msg_tw, msg_th, 1)

	if sweeping and band_l and love.graphics.transformPoint
		and love.graphics.intersectScissor and love.graphics.getScissor then
		local x1, y1 = love.graphics.transformPoint(band_l, -msg_th)
		local x2, y2 = love.graphics.transformPoint(band_r, msg_th)
		local psx, psy, psw, psh = love.graphics.getScissor()
		love.graphics.intersectScissor(
			math.min(x1, x2), math.min(y1, y2),
			math.abs(x2 - x1), math.abs(y2 - y1))
		local hr, hg, hb = hsv_to_rgb(((G.TIMERS.REAL or 0) * 1.2) % 1, 0.35, 1)
		love.graphics.setColor(hr, hg, hb, 0.92)
		love.graphics.print(msg, -msg_tw * 0.5, -msg_th * 0.5)
		if psx then
			love.graphics.setScissor(psx, psy, psw, psh)
		else
			love.graphics.setScissor()
		end
	end

	love.graphics.pop()
end

function M.draw()
	if not M.is_active() or not G.GAME or not G.ROOM then return end
	if G.STATE ~= G.STATES.TABLE_BOARD then return end

	local prev_font = love.graphics.getFont and love.graphics.getFont()
	local cr, cg, cb, ca = 1, 1, 1, 1
	if love.graphics.getColor then
		cr, cg, cb, ca = love.graphics.getColor()
	end
	local prev_shader = love.graphics.getShader and love.graphics.getShader()

	love.graphics.push()
	if love.graphics.setShader then love.graphics.setShader() end
	room_translate()

	if boss_banner then
		draw_banner(boss_banner)
	end
	if theme_banner then
		draw_banner(theme_banner)
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

M.draw_pass = M.draw

return M
