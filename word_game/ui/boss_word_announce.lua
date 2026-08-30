--[[
	word_game/ui/boss_word_announce.lua - Boss word ribbon aligned to the dealt hand.

	Sweeps the boss banner texture below the timeline timer, centered on the
	dealt hand row, then stays visible for the rest of the boss hand.
]]

local Layout = require("word_game.ui.layout")
local fonts = require("word_game.ui.score_banner.fonts")
local word_feedback = require("word_game.ui.word_feedback")

local M = {}

local SWEEP_TIME = 0.55
local SIZE_SCALE = 0.5
local TIMER_GAP_MIN_PX = 10
local TIMER_GAP_MAX_PX = 20
local TIMER_GAP_BASE_PX = 15
local REF_TILE_PX = 73

local state = nil

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

local function tile_scale_px()
	local tile = G.TILESIZE or 1
	local scale = G.TILESCALE or 1
	local px = tile * scale
	if px <= 0 then px = REF_TILE_PX end
	return px
end

local function timer_gap_tiles()
	local px_per_tile = tile_scale_px()
	local gap_px = math.max(
		TIMER_GAP_MIN_PX,
		math.min(TIMER_GAP_MAX_PX, TIMER_GAP_BASE_PX * (px_per_tile / REF_TILE_PX))
	)
	return gap_px / px_per_tile
end

local function measure_anchor()
	local timer = Layout.timeline_rect()
	local banner = Layout.banner_rect()
	if not timer or not banner then return nil end
	local hand = word_feedback.hand_dealt_metrics()
	local ts = G.TILESCALE * G.TILESIZE
	local banner_h = banner.h * SIZE_SCALE
	-- Ribbon art extends ~7.5% above the layout box; keep that clear of the timer.
	local ornament_pad = banner_h * 0.075
	local gap = timer_gap_tiles() + ornament_pad
	local top = timer.y + timer.h + gap
	local cx = hand and hand.cx or (timer.x + timer.w * 0.5)
	local cy = top + banner_h * 0.5
	return {
		cx = cx * ts,
		cy = cy * ts,
		w = ((hand and hand.gap_w) or banner.w) * ts * SIZE_SCALE,
		h = banner.h * ts * SIZE_SCALE,
	}
end

function M.is_active()
	return state ~= nil
end

function M.play(text)
	text = text or "BOSS WORD"
	if state and state.text == text then return end
	state = {
		text = text,
		t = 0,
		sweep_time = SWEEP_TIME,
	}
	if play_sfx then
		play_sfx("timpani", 0.95, 0.82)
	end
end

function M.clear()
	state = nil
end

function M.update(dt)
	if not state then return end
	if state.t < state.sweep_time then
		state.t = math.min(state.sweep_time, state.t + dt)
	end
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

function M.draw()
	if not state or not G.GAME or not G.ROOM then return end
	if G.STATE ~= G.STATES.TABLE_BOARD then return end

	local rect = measure_anchor()
	if not rect then return end

	local sweep_u = clamp01(state.t / state.sweep_time)
	local eased = 1 - (1 - sweep_u) * (1 - sweep_u) * (1 - sweep_u)
	local sweeping = sweep_u < 1

	local msg = state.text
	local msg_font_px = math.max(14, math.floor(rect.h * 0.58))
	local msg_font = fonts.title_font(msg_font_px)
	local msg_tw = msg_font:getWidth(msg)
	local msg_th = msg_font:getHeight()

	local prev_font = love.graphics.getFont and love.graphics.getFont()
	local cr, cg, cb, ca = 1, 1, 1, 1
	if love.graphics.getColor then
		cr, cg, cb, ca = love.graphics.getColor()
	end
	local prev_shader = love.graphics.getShader and love.graphics.getShader()

	love.graphics.push()
	if love.graphics.setShader then love.graphics.setShader() end
	room_translate()
	love.graphics.translate(rect.cx, rect.cy)

	local band_l, band_r = nil, nil
	local atlas = G.TEXTURE_ATLASES and G.TEXTURE_ATLASES.boss_banner
	if atlas and atlas.image and love.graphics.draw then
		local iw, ih = atlas.image:getDimensions()
		local img_h = rect.h * 1.15
		local img_w = img_h * (iw / ih)
		if img_w < rect.w * 1.3 then
			img_w = rect.w * 1.3
			img_h = img_w * (ih / iw)
		end
		local start_x = -(rect.w * 0.5 + img_w * 0.5 + 60)
		local bx = start_x + (0 - start_x) * eased
		band_l = bx - img_w * 0.5
		band_r = bx + img_w * 0.5
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.draw(atlas.image, band_l, -img_h * 0.5, 0, img_w / iw, img_h / ih)
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
