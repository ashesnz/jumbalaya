--[[
	word_game/ui/score_banner/boss_announce.lua - Boss stage ribbon below the timeline timer.

	Single sliding banner (e.g. "Boss Stage — Garden Theme") sits in the HUD gap above the
	score banner rect so it never overlaps the points/timer strip.
]]

local play_sfx = require("jumbalaya-engine.sound.sound").play_sfx

local facade = require("word_game.ui.facade")
local game_access = facade.game_access()
local game = require("word_game.ui.util.game_runtime").game

local Layout = require("word_game.ui.layout")
local fonts = require("word_game.ui.score_banner.fonts")

local M = {}

local SWEEP_TIME = 0.62
local SIZE_SCALE = 0.46
local TIMER_GAP_PX = 28
local BANNER_TOP_GAP_PX = 22
local REF_TILE_PX = 73
local RIBBON_HEIGHT_SCALE = 1.08
local RIBBON_MIN_WIDTH_SCALE = 1.22

local DEFAULT_THEME = "Garden Theme"
local STAGE_PREFIX = "Boss Stage"

local stage_banner = nil
local center_overlay = nil
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

function M.default_theme()
	return DEFAULT_THEME
end

function M.stage_message(theme)
	theme = theme or DEFAULT_THEME
	return STAGE_PREFIX .. " — " .. theme
end

local function room_translate()
	local room = game().ROOM
	if not room then return end
	local ts = game().TILESCALE * game().TILESIZE
	love.graphics.translate(room.T.w * ts * 0.5, room.T.h * ts * 0.5)
	love.graphics.rotate(room.T.r)
	love.graphics.translate(
		-room.T.w * ts * 0.5 + room.T.x * ts,
		-room.T.h * ts * 0.5 + room.T.y * ts
	)
end

local function pixels_per_tile()
	local px = (game().TILESIZE or 1) * (game().TILESCALE or 1)
	return px > 0 and px or REF_TILE_PX
end

local function px_to_tiles(px)
	return px / pixels_per_tile()
end

local function gap_tiles(px)
	local scale = pixels_per_tile() / REF_TILE_PX
	return px_to_tiles(px * scale)
end

local function ribbon_half_span_tiles(banner_h)
	return banner_h * 0.5 * RIBBON_HEIGHT_SCALE
end

local function stack_layout_tiles()
	local timer = Layout.timeline_rect()
	local score_banner = Layout.banner_rect()
	if not timer or not score_banner then return nil end
	local banner_h = score_banner.h * SIZE_SCALE
	local span = ribbon_half_span_tiles(banner_h)
	local cx = timer.x + timer.w * 0.5
	local w = score_banner.w * SIZE_SCALE
	local timer_bottom = timer.y + timer.h
	local score_top = score_banner.y
	local top_pad = gap_tiles(TIMER_GAP_PX)
	local bottom_pad = gap_tiles(BANNER_TOP_GAP_PX)
	local band_top = timer_bottom + top_pad
	local band_bottom = score_top - bottom_pad
	local band_h = band_bottom - band_top
	if band_h <= 0.02 then
		band_top = timer_bottom
		band_bottom = score_top
		band_h = band_bottom - band_top
	end
	local stage_cy = (band_top + band_bottom) * 0.5
	local max_span = math.max(0.08, band_h * 0.46)
	span = math.min(span, max_span)
	span = math.min(span, stage_cy - band_top, band_bottom - stage_cy)
	return {
		cx = cx,
		w = w,
		h = banner_h,
		span = span,
		stage_cy = stage_cy,
		timer_bottom = timer_bottom,
		score_top = score_top,
		band_top = band_top,
		band_bottom = band_bottom,
	}
end

local function stack_layout_pixels()
	local stack = stack_layout_tiles()
	if not stack then return nil end
	local ts = game().TILESCALE * game().TILESIZE
	return {
		cx = stack.cx * ts,
		w = stack.w * ts,
		h = stack.h * ts,
		stage_cy = stack.stage_cy * ts,
		span = stack.span * ts,
	}
end

local function ribbon_texture_size()
	local atlas = game().TEXTURE_ATLASES and game().TEXTURE_ATLASES.boss_banner
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

function M.measure_stack()
	local stack = stack_layout_tiles()
	if not stack then return nil end
	local ts = (game().TILESCALE or 1) * (game().TILESIZE or 1)
	local img_w_px, _, iw, ih = ribbon_size({ w = stack.w * ts, h = stack.h * ts })
	local img_w = img_w_px / ts
	local origin = ribbon_content_origin(iw, ih)
	local scale_x = img_w / iw
	local top = stack.stage_cy - stack.span
	local bottom = stack.stage_cy + stack.span
	local left = stack.cx + (origin.minx - origin.ox) * scale_x
	local right = stack.cx + (origin.maxx - origin.ox) * scale_x
	return {
		cx = stack.cx,
		w = stack.w,
		h = stack.h,
		span = stack.span,
		stage_cy = stack.stage_cy,
		timer_bottom = stack.timer_bottom,
		score_top = stack.score_top,
		top = top,
		bottom = bottom,
		left = left,
		right = right,
		fits_above_score = top >= stack.band_top and bottom <= stack.band_bottom,
	}
end

local function new_banner(text)
	return {
		text = text,
		t = 0,
		sweep_time = SWEEP_TIME,
	}
end

local function advance_banner(banner, dt)
	if not banner then return end
	if banner.t < banner.sweep_time then
		banner.t = math.min(banner.sweep_time, banner.t + dt)
	end
end

function M.is_active()
	return stage_banner ~= nil or center_overlay ~= nil
end

function M.has_center_overlay()
	return center_overlay ~= nil
end

function M.set_center_text(text, hold, kind)
	if not text or text == "" then
		center_overlay = nil
		return
	end
	center_overlay = {
		text = tostring(text),
		age = 0,
		life = hold or 0.85,
		alpha = 1,
		kind = kind or "countdown",
	}
end

local function advance_center_overlay(dt)
	if not center_overlay then return end
	center_overlay.age = (center_overlay.age or 0) + (dt or 0)
	local life = center_overlay.life or 0.85
	if center_overlay.age >= life then
		center_overlay = nil
		return
	end
	local fade_start = life * 0.72
	if center_overlay.age <= fade_start then
		center_overlay.alpha = 1
	else
		center_overlay.alpha = math.max(0, 1 - (center_overlay.age - fade_start) / math.max(0.01, life - fade_start))
	end
end

function M.play(text)
	text = text or M.stage_message()
	if stage_banner and stage_banner.text == text then return end
	stage_banner = new_banner(text)
	if play_sfx then
		play_sfx("timpani", 0.95, 0.82)
	end
end

function M.play_stage(theme)
	M.play(M.stage_message(theme))
end

function M.clear()
	stage_banner = nil
	center_overlay = nil
end

function M.update(dt)
	advance_banner(stage_banner, dt)
	advance_center_overlay(dt)
end

local function split_stage_message(text)
	local sep = " — "
	local i = text:find(sep, 1, true)
	if i then
		return text:sub(1, i - 1), text:sub(i + #sep)
	end
	sep = " - "
	i = text:find(sep, 1, true)
	if i then
		return text:sub(1, i - 1), text:sub(i + #sep)
	end
	return text, nil
end

local function draw_text_shadow(msg, tx, ty, alpha, r, g, b)
	love.graphics.setColor(0.04, 0.07, 0.12, 0.62 * alpha)
	love.graphics.print(msg, tx + 1.5, ty + 2.5)
	love.graphics.setColor(r, g, b, alpha)
	love.graphics.print(msg, tx, ty)
	love.graphics.setColor(1, 1, 1, 0.18 * alpha)
	love.graphics.print(msg, tx, ty - 1)
end

local function draw_stage_label(msg, stack, sweep_u)
	local title, theme = split_stage_message(msg)
	local base_px = math.max(13, math.floor(stack.h * 0.52))
	local title_font = fonts.title_font(base_px)
	local theme_font = theme and fonts.title_font(math.max(12, math.floor(base_px * 0.88))) or title_font

	local text_alpha = clamp01((sweep_u - 0.42) / 0.35)
	local settle = clamp01((sweep_u - 0.78) / 0.22)
	local breathe = 1 + math.sin((game().TIMERS.REAL or 0) * 4.2) * 0.012 * settle

	if theme then
		local tw_t = title_font:getWidth(title)
		local tw_th = title_font:getWidth(" — ")
		local tw_m = theme_font:getWidth(theme)
		local th = math.max(title_font:getHeight(), theme_font:getHeight())
		local total_w = tw_t + tw_th + tw_m
		local x0 = -total_w * 0.5
		local y0 = -th * 0.5

		love.graphics.push()
		love.graphics.scale(breathe, breathe)
		love.graphics.setFont(title_font)
		draw_text_shadow(title, x0, y0, text_alpha, 0.98, 0.93, 0.78)
		love.graphics.setFont(theme_font)
		local sep_x = x0 + tw_t
		draw_text_shadow(" — ", sep_x, y0 + (title_font:getHeight() - theme_font:getHeight()) * 0.5, text_alpha * 0.55, 0.72, 0.78, 0.86)
		local tr, tg, tb = hsv_to_rgb(0.38, 0.42, 0.98)
		draw_text_shadow(theme, sep_x + tw_th, y0 + (title_font:getHeight() - theme_font:getHeight()) * 0.08, text_alpha, tr, tg, tb)
		love.graphics.pop()
		return
	end

	love.graphics.setFont(title_font)
	local tw = title_font:getWidth(msg)
	local th = title_font:getHeight()
	love.graphics.push()
	love.graphics.scale(breathe, breathe)
	draw_text_shadow(msg, -tw * 0.5, -th * 0.5, text_alpha, 0.96, 0.93, 0.86)
	love.graphics.pop()
end

local function settle_glow(sweep_u)
	return clamp01((sweep_u - 0.7) / 0.3)
end

local function draw_stage_banner(banner, stack, img_w, img_h)
	local sweep_u = clamp01(banner.t / banner.sweep_time)
	local eased = 1 - (1 - sweep_u) * (1 - sweep_u) * (1 - sweep_u)
	local sweeping = sweep_u < 1

	love.graphics.push()
	love.graphics.translate(stack.cx, stack.stage_cy)

	local band_l, band_r, band_cx = nil, nil, nil
	local atlas = game().TEXTURE_ATLASES and game().TEXTURE_ATLASES.boss_banner
	if atlas and atlas.image and love.graphics.draw then
		local iw, ih = atlas.image:getDimensions()
		local origin = ribbon_content_origin(iw, ih)
		local offscreen = stack.w * 0.5 + img_w * 0.5 + 80
		local start_x = offscreen
		band_cx = start_x + (0 - start_x) * eased
		band_l = band_cx - img_w * 0.5
		band_r = band_cx + img_w * 0.5
		local ribbon_alpha = 0.92 + settle_glow(sweep_u) * 0.08
		love.graphics.setColor(1, 1, 1, ribbon_alpha)
		local sx = img_w / iw
		love.graphics.draw(atlas.image, band_cx, 0, 0, sx, img_h / ih, origin.ox, origin.oy)
	end

	draw_stage_label(banner.text, stack, sweep_u)

	if sweeping and band_l and love.graphics.transformPoint
		and love.graphics.intersectScissor and love.graphics.getScissor then
		local font_h = math.max(14, stack.h * 0.5)
		local x1, y1 = love.graphics.transformPoint(band_l, -font_h)
		local x2, y2 = love.graphics.transformPoint(band_r, font_h)
		local psx, psy, psw, psh = love.graphics.getScissor()
		love.graphics.intersectScissor(
			math.min(x1, x2), math.min(y1, y2),
			math.abs(x2 - x1), math.abs(y2 - y1))
		draw_stage_label(banner.text, stack, 1)
		if psx then
			love.graphics.setScissor(psx, psy, psw, psh)
		else
			love.graphics.setScissor()
		end
	end

	love.graphics.pop()
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

local function draw_center_overlay()
	if not center_overlay or not love or not love.graphics then return end
	local felt = Layout.felt_rect and Layout.felt_rect()
	if not felt then return end
	local ts = (game().TILESCALE or 1) * (game().TILESIZE or 1)
	local cx = (felt.x + felt.w * 0.5) * ts
	local cy = (felt.y + felt.h * (center_overlay.kind == "title" and 0.42 or 0.48)) * ts
	local px = center_overlay.kind == "title" and 44 or 96
	local font = fonts.title_font(px)
	love.graphics.setFont(font)
	local msg = center_overlay.text
	local tw = font:getWidth(msg)
	local th = font:getHeight()
	local alpha = center_overlay.alpha or 1
	love.graphics.push()
	love.graphics.translate(cx, cy)
	draw_professional_text(msg, tw, th, alpha)
	love.graphics.pop()
end

function M.draw()
	if not M.is_active() or not game_access.get() or not game().ROOM then return end
	if game().STATE ~= game().STATES.TABLE_BOARD then return end

	local stack = stack_layout_pixels()
	if not stack and not center_overlay then return end
	local img_w, img_h = 0, 0
	if stack then
		img_w, img_h = ribbon_size(stack)
	end

	local prev_font = love.graphics.getFont and love.graphics.getFont()
	local cr, cg, cb, ca = 1, 1, 1, 1
	if love.graphics.getColor then
		cr, cg, cb, ca = love.graphics.getColor()
	end
	local prev_shader = love.graphics.getShader and love.graphics.getShader()

	love.graphics.push()
	if love.graphics.setShader then love.graphics.setShader() end
	room_translate()

	if stage_banner and stack then
		draw_stage_banner(stage_banner, stack, img_w, img_h)
	end

	if center_overlay then
		draw_center_overlay()
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
