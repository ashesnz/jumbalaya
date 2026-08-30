--[[
	word_game/ui/timeline_timer.lua - Mathematical timeline timer HUD.

	Replaces Milo with a dynamic timeline bar that animates from green to red
	starting from the right-hand side over 60 seconds like a burning fuse,
	featuring an overlay countdown timer (60 to 0) drawn mathematically without images.
]]

local Layout = require("word_game.ui.layout")
local StageLabel = require("word_game.ui.stage_label")

local M = {}

M.TOTAL_DURATION = 60.0
M.time_remaining = 60.0
M.is_active = true
M.frozen_for_reward = false
M.sparks = {}

local FONT_FILE = "resources/fonts/Outfit-Bold.ttf"
local font_cache = {}

local GREEN_TOP = { 0.38, 0.88, 0.48, 1 }
local GREEN_MID = { 0.22, 0.78, 0.35, 1 }
local GREEN_BOT = { 0.14, 0.60, 0.24, 1 }

local RED_TOP = { 0.95, 0.28, 0.32, 1 }
local RED_MID = { 0.82, 0.16, 0.22, 1 }
local RED_BOT = { 0.58, 0.08, 0.14, 1 }

local SPARK_CORE = { 1.00, 0.98, 0.85, 1 }
local SPARK_GLOW = { 1.00, 0.65, 0.12, 0.85 }
local BORDER_COLOR = { 0.10, 0.15, 0.26, 1 }
local SHADOW_COLOR = { 0.03, 0.05, 0.10, 0.35 }

local function clamp01(t)
	if t < 0 then return 0 end
	if t > 1 then return 1 end
	return t
end

local function timer_font(px)
	px = math.max(12, math.floor(px + 0.5))
	local cached = font_cache[px]
	if cached then return cached end
	local font = nil
	if love and love.graphics and love.graphics.newFont then
		local ok, f = pcall(love.graphics.newFont, FONT_FILE, px)
		if ok and f then
			font = f
		else
			font = love.graphics.newFont(px)
		end
		font:setFilter("linear", "linear")
	end
	font_cache[px] = font
	return font
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

-- Formats the countdown timer text:
-- Whole number (>= 10s), 1 decimal point (< 10s and >= 5s), 2 decimal points (< 5s).
function M.format_time(time_val)
	local t = math.max(0, time_val or 0)
	if M.frozen_for_reward then
		return string.format("%d", math.floor(t + 1e-9))
	end
	if t >= 10 then
		return string.format("%d", math.floor(t + 1e-9))
	elseif t >= 5 then
		return string.format("%.1f", t)
	else
		return string.format("%.2f", t)
	end
end

-- Builds polygon vertices for the timeline shape: rounded left edge, straight top/bottom, slanted right edge.
function M.build_shape_polygon(x, y, w, h, slant, r, n_arc)
	n_arc = n_arc or 6
	local verts = {}

	-- 1. Top-left rounded arc (180 to 270 deg)
	for i = 0, n_arc do
		local ang = math.pi + (math.pi * 0.5) * (i / n_arc)
		table.insert(verts, x + r + r * math.cos(ang))
		table.insert(verts, y + r + r * math.sin(ang))
	end

	-- 2. Top-right slanted corner
	local tr_x = x + w - slant
	local tr_y = y
	local slant_ang = math.atan2(h, slant)
	table.insert(verts, tr_x - r * 0.5)
	table.insert(verts, tr_y)
	table.insert(verts, tr_x + r * 0.3 * math.cos(slant_ang))
	table.insert(verts, tr_y + r * 0.3 * math.sin(slant_ang))

	-- 3. Bottom-right slanted corner
	local br_x = x + w
	local br_y = y + h
	table.insert(verts, br_x - r * 0.3 * math.cos(slant_ang))
	table.insert(verts, br_y - r * 0.3 * math.sin(slant_ang))
	table.insert(verts, br_x - r * 0.5)
	table.insert(verts, br_y)

	-- 4. Bottom-left rounded arc (90 to 180 deg)
	for i = 0, n_arc do
		local ang = (math.pi * 0.5) + (math.pi * 0.5) * (i / n_arc)
		table.insert(verts, x + r + r * math.cos(ang))
		table.insert(verts, y + h - r + r * math.sin(ang))
	end

	return verts
end

-- Builds polygon vertices for the remaining green portion
function M.build_green_polygon(x, y, w, h, slant, r, frac, n_arc)
	if frac <= 0.001 then return nil end
	if frac >= 0.999 then
		return M.build_shape_polygon(x, y, w, h, slant, r, n_arc)
	end

	n_arc = n_arc or 6
	local verts = {}

	-- 1. Top-left rounded arc (180 to 270 deg)
	for i = 0, n_arc do
		local ang = math.pi + (math.pi * 0.5) * (i / n_arc)
		table.insert(verts, x + r + r * math.cos(ang))
		table.insert(verts, y + r + r * math.sin(ang))
	end

	-- 2. Slanted right edge at the current fuse split
	local top_split_x = x + (w - slant) * frac
	local bot_split_x = x + w * frac
	table.insert(verts, top_split_x)
	table.insert(verts, y)
	table.insert(verts, bot_split_x)
	table.insert(verts, y + h)

	-- 3. Bottom-left rounded arc (90 to 180 deg)
	for i = 0, n_arc do
		local ang = (math.pi * 0.5) + (math.pi * 0.5) * (i / n_arc)
		table.insert(verts, x + r + r * math.cos(ang))
		table.insert(verts, y + h - r + r * math.sin(ang))
	end

	return verts
end

function M.reset(duration)
	M.TOTAL_DURATION = duration or 60.0
	M.time_remaining = M.TOTAL_DURATION
	M.is_active = true
	M.frozen_for_reward = false
	M.sparks = {}
	StageLabel.sync()
end

function M.pause()
	M.is_active = false
	M.frozen_for_reward = false
end

function M.resume()
	M.is_active = true
	M.frozen_for_reward = false
end

function M.freeze_reward_display(token_amount)
	token_amount = math.max(0, math.floor(token_amount or 0))
	M.time_remaining = token_amount
	M.is_active = false
	M.frozen_for_reward = true
end

function M.set_time(time_seconds)
	M.time_remaining = math.max(0, math.min(M.TOTAL_DURATION, time_seconds or M.TOTAL_DURATION))
end

function M.add_time(seconds)
	seconds = seconds or 0
	if seconds <= 0 then return end
	M.time_remaining = math.min(M.TOTAL_DURATION, M.time_remaining + seconds)
end

function M.update(dt)
	dt = dt or 0
	if M.is_active and M.time_remaining > 0 then
		M.time_remaining = math.max(0, M.time_remaining - dt)
	end

	-- Update spark particles
	for i = #M.sparks, 1, -1 do
		local s = M.sparks[i]
		s.age = s.age + dt
		s.x = s.x + s.vx * dt
		s.y = s.y + s.vy * dt
		s.alpha = math.max(0, 1 - s.age / s.life)
		if s.age >= s.life then
			table.remove(M.sparks, i)
		end
	end

	StageLabel.update(dt)

	-- Spawn new ember sparks at fuse boundary when active
	if M.time_remaining > 0 and M.time_remaining < M.TOTAL_DURATION and #M.sparks < 25 then
		if math.random() < 0.65 then
			table.insert(M.sparks, {
				x = 0,
				y = 0,
				vx = (math.random() - 0.5) * 35,
				vy = -math.random(20, 65),
				size = math.random(2, 5),
				age = 0,
				life = 0.25 + math.random() * 0.35,
				alpha = 1,
				color = math.random() < 0.5 and SPARK_CORE or SPARK_GLOW,
			})
		end
	end
end

function M.draw()
	if not love or not love.graphics or not love.graphics.polygon then return end
	if not G.GAME or not G.ROOM then return end
	if G.STATE ~= G.STATES.TABLE_BOARD then return end

	local dt = math.min(0.05, love.timer and love.timer.getDelta() or 0.016)
	M.update(dt)

	local ts = (G.TILESCALE or 1) * (G.TILESIZE or 1)
	local rect = Layout.timeline_rect and Layout.timeline_rect() or Layout.portrait_rect()
	local w = rect.w * ts
	local h = rect.h * ts
	local slant = (rect.slant or (rect.h * 0.88)) * ts
	local x = rect.x * ts
	local y = rect.y * ts
	local r = math.max(4, h * 0.18)

	local prev_font = love.graphics.getFont and love.graphics.getFont()
	local cr, cg, cb, ca = 1, 1, 1, 1
	if love.graphics.getColor then
		cr, cg, cb, ca = love.graphics.getColor()
	end
	local prev_shader = love.graphics.getShader and love.graphics.getShader()

	love.graphics.push()
	love.graphics.setShader()
	room_translate()

	if love.graphics.setLineStyle then
		love.graphics.setLineStyle("smooth")
	end
	if love.graphics.setLineJoin then
		love.graphics.setLineJoin("bevel")
	end

	StageLabel.draw_above_timer(x, y, w, h)

	local shape_verts = M.build_shape_polygon(x, y, w, h, slant, r)

	-- 1. Outer drop shadow
	for i = 4, 1, -1 do
		love.graphics.setColor(SHADOW_COLOR[1], SHADOW_COLOR[2], SHADOW_COLOR[3], SHADOW_COLOR[4] * (i / 4))
		local shadow_verts = M.build_shape_polygon(x + i * 0.8, y + i * 1.8, w, h, slant, r)
		love.graphics.polygon("fill", unpack(shadow_verts))
	end

	-- Fraction of remaining green from left (1.0 = full green, 0.0 = full red)
	local frac_remaining = clamp01(M.time_remaining / M.TOTAL_DURATION)
	local top_split_x = x + (w - slant) * frac_remaining
	local bot_split_x = x + w * frac_remaining

	-- 2. Draw timeline base (Red / Burnt fuse portion)
	love.graphics.setColor(RED_MID)
	love.graphics.polygon("fill", unpack(shape_verts))

	-- Draw Green (Remaining time) Portion on the left
	local green_verts = M.build_green_polygon(x, y, w, h, slant, r, frac_remaining)
	if green_verts then
		love.graphics.setColor(GREEN_MID)
		love.graphics.polygon("fill", unpack(green_verts))
	end

	-- Draw Glowing Fuse Burning Seam
	if frac_remaining > 0.001 and frac_remaining < 0.999 then
		local real_time = (G.TIMERS and G.TIMERS.REAL) or 0
		local flicker = math.sin(real_time * 24) * 0.15 + math.cos(real_time * 37) * 0.1

		-- Outer glow along the seam
		love.graphics.setLineWidth(math.max(6, h * 0.18))
		love.graphics.setColor(SPARK_GLOW[1], SPARK_GLOW[2], SPARK_GLOW[3], 0.75 + flicker)
		love.graphics.line(top_split_x, y - 2, bot_split_x, y + h + 2)

		-- Core hot spark line
		love.graphics.setLineWidth(math.max(2.5, h * 0.08))
		love.graphics.setColor(SPARK_CORE[1], SPARK_CORE[2], SPARK_CORE[3], 0.95)
		love.graphics.line(top_split_x, y, bot_split_x, y + h)

		-- Glowing ember sparks along the fuse
		local mid_fuse_x = (top_split_x + bot_split_x) * 0.5
		local mid_fuse_y = y + h * 0.5
		love.graphics.setColor(SPARK_CORE[1], SPARK_CORE[2], SPARK_CORE[3], 0.85 + flicker)
		love.graphics.circle("fill", mid_fuse_x, mid_fuse_y, math.max(3, h * 0.14))
		love.graphics.setColor(SPARK_GLOW[1], SPARK_GLOW[2], SPARK_GLOW[3], 0.45)
		love.graphics.circle("fill", mid_fuse_x, mid_fuse_y, math.max(6, h * 0.28))
	end

	-- 3. Outer border outline
	love.graphics.setLineWidth(math.max(2.5, h * 0.065))
	love.graphics.setColor(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], BORDER_COLOR[4])
	love.graphics.polygon("line", unpack(shape_verts))

	-- 4. Draw Ember Spark Particles
	local mid_fuse_x = (top_split_x + bot_split_x) * 0.5
	local mid_fuse_y = y + h * 0.5
	for _, s in ipairs(M.sparks) do
		local sx = mid_fuse_x + s.x
		local sy = mid_fuse_y + s.y
		love.graphics.setColor(s.color[1], s.color[2], s.color[3], s.alpha)
		love.graphics.circle("fill", sx, sy, s.size)
	end

	-- 5. Draw Countdown Timer Text (60 to 0) centered on top of the shape
	local count_str = M.format_time(M.time_remaining)
	local font_px = math.max(16, h * 0.62)
	local font = timer_font(font_px)

	if font then
		love.graphics.setFont(font)
		local tw = font:getWidth(count_str)
		local th = font:getHeight()
		local text_cx = x + (w - slant * 0.5) * 0.5
		local text_cy = y + h * 0.5

		-- Text Drop Shadows / Outline for crystal clarity over both green and red backgrounds
		love.graphics.setColor(0.04, 0.06, 0.12, 0.90)
		for ox = -1.5, 1.5, 1.5 do
			for oy = -1.5, 1.5, 1.5 do
				if ox ~= 0 or oy ~= 0 then
					love.graphics.print(count_str, text_cx - tw * 0.5 + ox, text_cy - th * 0.5 + oy + 0.5)
				end
			end
		end

		-- Extra bottom shadow
		love.graphics.setColor(0.02, 0.03, 0.06, 0.85)
		love.graphics.print(count_str, text_cx - tw * 0.5 + 1.5, text_cy - th * 0.5 + 2.0)

		-- Main Text Color
		if M.time_remaining <= 10 and M.time_remaining > 0 then
			local pulse_red = math.abs(math.sin(((G.TIMERS and G.TIMERS.REAL) or 0) * 8))
			love.graphics.setColor(1.0, 0.85 - pulse_red * 0.35, 0.85 - pulse_red * 0.35, 1)
		else
			love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
		end
		love.graphics.print(count_str, text_cx - tw * 0.5, text_cy - th * 0.5)
	end

	love.graphics.pop()
	if prev_font and love.graphics.setFont then
		love.graphics.setFont(prev_font)
	end
	if love.graphics.setColor then
		love.graphics.setColor(cr, cg, cb, ca)
	end
	if prev_shader and love.graphics.setShader then
		love.graphics.setShader(prev_shader)
	end
end

return M
