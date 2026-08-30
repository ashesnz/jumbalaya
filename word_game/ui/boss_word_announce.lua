--[[
	word_game/ui/boss_word_announce.lua - Boss countdown ribbons below the timer.

	Boss word: sweeps left-to-right at "Are you ready?"
	Theme: sweeps right-to-left at "1", mirrored below boss with a gap — arrowhead stack.
]]

local Layout = require("word_game.ui.layout")
local fonts = require("word_game.ui.score_banner.fonts")
local word_feedback = require("word_game.ui.word_feedback")

local M = {}

local SWEEP_TIME = 0.55
local SIZE_SCALE = 0.5
local TIMER_GAP_PX = 45
local REF_TILE_PX = 73
local RIBBON_HEIGHT_SCALE = 1.15
local RIBBON_MIN_WIDTH_SCALE = 1.3

local boss_banner = nil
local theme_banner = nil
local content_origin = nil
local BANNER_IMAGE_PATH = "resources/assets/banner.png"

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

local function banner_gap_tiles()
	local scale = pixels_per_tile() / REF_TILE_PX
	return px_to_tiles(TIMER_GAP_PX * scale)
end

local function ribbon_half_span_tiles(banner_h)
	return banner_h * 0.5 * RIBBON_HEIGHT_SCALE
end

local function stack_layout_tiles()
	local timer = Layout.timeline_rect()
	local banner = Layout.banner_rect()
	if not timer or not banner then return nil end
	local banner_h = banner.h * SIZE_SCALE
	local span = ribbon_half_span_tiles(banner_h)
	local cx = timer.x + timer.w * 0.5
	local w = banner.w * SIZE_SCALE
	local boss_cy = timer.y + timer.h + banner_gap_tiles() + span
	local gap = banner_gap_tiles()
	local theme_cy = boss_cy + span + gap + span
	return {
		cx = cx,
		w = w,
		h = banner_h,
		span = span,
		gap = gap,
		boss_cy = boss_cy,
		theme_cy = theme_cy,
	}
end

local function stack_layout_pixels()
	local stack = stack_layout_tiles()
	if not stack then return nil end
	local ts = G.TILESCALE * G.TILESIZE
	return {
		cx = stack.cx * ts,
		w = stack.w * ts,
		h = stack.h * ts,
		boss_cy = stack.boss_cy * ts,
		theme_cy = stack.theme_cy * ts,
	}
end

local function ribbon_texture_size()
	local atlas = G.TEXTURE_ATLASES and G.TEXTURE_ATLASES.boss_banner
	if atlas and atlas.image and atlas.image.getDimensions then
		return atlas.image:getDimensions()
	end
	return 1180, 211
end

local function ribbon_size(rect)
	local iw, ih = ribbon_texture_size()
	local img_h = rect.h * RIBBON_HEIGHT_SCALE
	local img_w = img_h * (iw / ih)
	if img_w < rect.w * RIBBON_MIN_WIDTH_SCALE then
		img_w = rect.w * RIBBON_MIN_WIDTH_SCALE
		img_h = img_w * (ih / iw)
	end
	return img_w, img_h, iw, ih
end

-- Opaque ribbon art is not centered in banner.png (more padding on the left).
-- Flipping around the texture midpoint therefore shifts Garden left by ~10–20px.
-- Both ribbons pivot around the opaque content center so visual corners match.
local function scan_opaque_bounds(iw, ih)
	if not (love and love.image and love.image.newImageData) then
		return nil
	end
	local ok, data = pcall(love.image.newImageData, BANNER_IMAGE_PATH)
	if not ok or not data or not data.getPixel then
		return nil
	end
	iw = data.getWidth and data:getWidth() or iw
	ih = data.getHeight and data:getHeight() or ih
	local minx, maxx = iw, -1
	local miny, maxy = ih, -1
	for y = 0, ih - 1 do
		for x = 0, iw - 1 do
			local r, g, b, a = data:getPixel(x, y)
			if (a or 0) > 0.06 then
				if x < minx then minx = x end
				if x > maxx then maxx = x end
				if y < miny then miny = y end
				if y > maxy then maxy = y end
			end
		end
	end
	if maxx < minx then
		return nil
	end
	return { minx = minx, maxx = maxx, miny = miny, maxy = maxy }
end

local function ribbon_content_origin(iw, ih)
	if content_origin and content_origin.iw == iw and content_origin.ih == ih then
		return content_origin
	end
	local bounds = content_origin and content_origin.forced
	if not bounds then
		bounds = scan_opaque_bounds(iw, ih)
	end
	if not bounds then
		bounds = { minx = 0, maxx = iw - 1, miny = 0, maxy = ih - 1 }
	end
	content_origin = {
		iw = iw,
		ih = ih,
		minx = bounds.minx,
		maxx = bounds.maxx,
		ox = (bounds.minx + bounds.maxx) * 0.5,
		oy = ih * 0.5,
		forced = content_origin and content_origin.forced,
	}
	return content_origin
end

function M.set_content_bounds_for_test(bounds)
	content_origin = bounds and { forced = bounds } or nil
end

-- Testable layout: shared visual corners, separated ribbon bodies (arrowhead stack).
function M.measure_stack()
	local stack = stack_layout_tiles()
	if not stack then return nil end
	local ts = (G.TILESCALE or 1) * (G.TILESIZE or 1)
	local img_w_px, _, iw, ih = ribbon_size({ w = stack.w * ts, h = stack.h * ts })
	local img_w = img_w_px / ts
	local origin = ribbon_content_origin(iw, ih)
	local scale_x = img_w / iw
	local boss_top = stack.boss_cy - stack.span
	local boss_bottom = stack.boss_cy + stack.span
	local theme_top = stack.theme_cy - stack.span
	local theme_bottom = stack.theme_cy + stack.span
	local boss_left = stack.cx + (origin.minx - origin.ox) * scale_x
	local boss_right = stack.cx + (origin.maxx - origin.ox) * scale_x
	local garden_left = stack.cx + (origin.maxx - origin.ox) * (-scale_x)
	local garden_right = stack.cx + (origin.minx - origin.ox) * (-scale_x)
	return {
		cx = stack.cx,
		w = stack.w,
		h = stack.h,
		span = stack.span,
		gap = stack.gap,
		boss_cy = stack.boss_cy,
		theme_cy = stack.theme_cy,
		img_w = img_w,
		left = boss_left,
		right = boss_right,
		boss_top = boss_top,
		boss_bottom = boss_bottom,
		theme_top = theme_top,
		theme_bottom = theme_bottom,
		ribbon_gap = theme_top - boss_bottom,
		boss_bottom_left = { x = boss_left, y = boss_bottom },
		boss_bottom_right = { x = boss_right, y = boss_bottom },
		garden_top_left = { x = garden_left, y = theme_top },
		garden_top_right = { x = garden_right, y = theme_top },
	}
end

local function new_banner(text, opts)
	opts = opts or {}
	return {
		text = text,
		t = 0,
		sweep_time = SWEEP_TIME,
		direction = opts.direction or "ltr",
		mirror = opts.mirror or false,
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
	theme_banner = new_banner(text, { direction = "rtl", mirror = true, slot = "theme" })
end

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

local function draw_banner(banner, stack, img_w, img_h)
	local cy = banner.slot == "theme" and stack.theme_cy or stack.boss_cy
	local sweep_u = clamp01(banner.t / banner.sweep_time)
	local eased = 1 - (1 - sweep_u) * (1 - sweep_u) * (1 - sweep_u)
	local sweeping = sweep_u < 1
	local from_right = banner.direction == "rtl"

	local msg = banner.text
	local msg_font_px = math.max(14, math.floor(stack.h * 0.58))
	local msg_font = fonts.title_font(msg_font_px)
	local msg_tw = msg_font:getWidth(msg)
	local msg_th = msg_font:getHeight()

	love.graphics.push()
	love.graphics.translate(stack.cx, cy)

	local band_l, band_r, band_cx = nil, nil, nil
	local atlas = G.TEXTURE_ATLASES and G.TEXTURE_ATLASES.boss_banner
	if atlas and atlas.image and love.graphics.draw then
		local iw, ih = atlas.image:getDimensions()
		local origin = ribbon_content_origin(iw, ih)
		local offscreen = stack.w * 0.5 + img_w * 0.5 + 60
		local start_x = from_right and offscreen or -offscreen
		band_cx = start_x + (0 - start_x) * eased
		band_l = band_cx - img_w * 0.5
		band_r = band_cx + img_w * 0.5
		love.graphics.setColor(1, 1, 1, 1)
		local sx = img_w / iw
		if banner.mirror then
			sx = -sx
		end
		love.graphics.draw(atlas.image, band_cx, 0, 0, sx, img_h / ih, origin.ox, origin.oy)
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

	local stack = stack_layout_pixels()
	if not stack then return end
	local img_w, img_h = ribbon_size(stack)

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
		draw_banner(boss_banner, stack, img_w, img_h)
	end
	if theme_banner then
		draw_banner(theme_banner, stack, img_w, img_h)
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
