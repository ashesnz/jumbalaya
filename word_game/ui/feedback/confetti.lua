--[[
	word_game/ui/confetti.lua - Win celebration raining from the score banner.

	Stars / discs / petals / kites in a muted paper palette, falling from the
	hexagon plate down across the card felt.
]]

local Layout = require("word_game.ui.layout")

local M = {}

local COLOURS = {
	{ 0.62, 0.72, 0.58, 1 }, -- sage
	{ 0.90, 0.78, 0.62, 1 }, -- sand
	{ 0.78, 0.58, 0.50, 1 }, -- clay
	{ 0.58, 0.70, 0.72, 1 }, -- sea glass
	{ 0.84, 0.70, 0.64, 1 }, -- blush taupe
	{ 0.70, 0.66, 0.52, 1 }, -- khaki
	{ 0.72, 0.62, 0.58, 1 }, -- dusty cocoa
	{ 0.66, 0.74, 0.68, 1 }, -- eucalyptus
}

local SHAPES = { "star", "disc", "petal", "kite" }

local pieces = {}
local rain_left = 0
local rain_acc = 0
local RAIN_GAP = 0.018
local GRAVITY = 5.6

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

local function felt()
	return Layout.felt_rect()
end

local function clip_rect()
	local banner = Layout.banner_rect()
	local r = felt()
	if not banner or not r then return r end
	return {
		x = r.x,
		y = banner.y,
		w = r.w,
		h = (r.y + r.h) - banner.y,
	}
end

local function star_verts(s)
	local verts = {}
	for i = 0, 9 do
		local a = -math.pi / 2 + i * math.pi / 5
		local r = (i % 2 == 0) and s or s * 0.42
		verts[#verts + 1] = math.cos(a) * r
		verts[#verts + 1] = math.sin(a) * r
	end
	return verts
end

local function kite_verts(s)
	return {
		0, -s,
		s * 0.62, 0,
		0, s * 0.82,
		-s * 0.62, 0,
	}
end

local function petal_verts(s)
	return {
		0, -s,
		s * 0.55, -s * 0.28,
		s * 0.48, s * 0.38,
		0, s,
		-s * 0.48, s * 0.38,
		-s * 0.55, -s * 0.28,
	}
end

local function spawn_rain()
	local banner = Layout.banner_rect()
	if not banner then return end
	local size = 0.05 + love.math.random() * 0.05
	pieces[#pieces + 1] = {
		shape = SHAPES[love.math.random(#SHAPES)],
		colour = COLOURS[love.math.random(#COLOURS)],
		size = size,
		x = banner.x + banner.w * (0.08 + love.math.random() * 0.84),
		y = banner.y + banner.h * 0.55,
		vx = (love.math.random() - 0.5) * 0.7,
		vy = 0.9 + love.math.random() * 1.4,
		sway = 0.22 + love.math.random() * 0.28,
		spin = 3.8 + love.math.random() * 2.8,
		phase = love.math.random() * math.pi * 2,
		tilt = 0.55 + love.math.random() * 0.5,
		age = 0,
		life = 1.85 + love.math.random() * 0.55,
		pop = 1,
	}
end

function M.burst()
	pieces = {}
	rain_left = 92
	rain_acc = 0
	for _ = 1, 18 do
		spawn_rain()
	end
end

function M.clear()
	pieces = {}
	rain_left = 0
	rain_acc = 0
end

function M.update(dt)
	dt = dt or 0
	if rain_left > 0 then
		rain_acc = rain_acc + dt
		while rain_left > 0 and rain_acc >= RAIN_GAP do
			rain_acc = rain_acc - RAIN_GAP
			spawn_rain()
			rain_left = rain_left - 1
		end
	end

	local r = felt()
	local bottom = r and (r.y + r.h + 0.2) or 99
	for i = #pieces, 1, -1 do
		local p = pieces[i]
		p.age = p.age + dt
		local t = p.age
		p.pop = math.min(1, t / 0.1)
		p.vy = p.vy + GRAVITY * dt
		p.x = p.x + p.vx * dt + math.sin(t * p.spin + p.phase) * p.sway * dt * 4.2
		p.y = p.y + p.vy * dt
		p.facing = p.tilt * math.sin(t * p.spin + p.phase)

		if t >= p.life or p.y > bottom then
			table.remove(pieces, i)
		end
	end
end

local function paint_shape(p, ts)
	local s = p.size * p.pop * ts
	local fade_start = p.life * 0.7
	local fade = 1
	if p.age > fade_start then
		fade = math.max(0, 1 - (p.age - fade_start) / (p.life - fade_start))
	end
	local c = p.colour
	love.graphics.setColor(c[1], c[2], c[3], (c[4] or 1) * fade)

	if p.shape == "disc" then
		love.graphics.circle("fill", 0, 0, s * 0.72)
	elseif p.shape == "star" then
		love.graphics.polygon("fill", unpack(star_verts(s)))
	elseif p.shape == "kite" then
		love.graphics.polygon("fill", unpack(kite_verts(s)))
	else
		love.graphics.polygon("fill", unpack(petal_verts(s)))
	end
end

function M.draw()
	if not G.GAME or not G.ROOM then return end
	if G.STATE ~= G.STATES.TABLE_BOARD then return end
	if #pieces == 0 and rain_left <= 0 then return end

	local r = clip_rect()
	if not r then return end
	local ts = G.TILESCALE * G.TILESIZE

	local prev_shader = love.graphics.getShader and love.graphics.getShader()
	local cr, cg, cb, ca = 1, 1, 1, 1
	if love.graphics.getColor then
		cr, cg, cb, ca = love.graphics.getColor()
	end

	love.graphics.push()
	if love.graphics.setShader then love.graphics.setShader() end
	room_translate()

	local psx, psy, psw, psh = nil, nil, nil, nil
	if love.graphics.transformPoint and love.graphics.intersectScissor and love.graphics.getScissor and love.graphics.setScissor then
		local x1, y1 = love.graphics.transformPoint(r.x * ts, r.y * ts)
		local x2, y2 = love.graphics.transformPoint((r.x + r.w) * ts, r.y * ts)
		local x3, y3 = love.graphics.transformPoint(r.x * ts, (r.y + r.h) * ts)
		local x4, y4 = love.graphics.transformPoint((r.x + r.w) * ts, (r.y + r.h) * ts)
		local sx = math.min(x1, x2, x3, x4)
		local sy = math.min(y1, y2, y3, y4)
		local sw = math.max(x1, x2, x3, x4) - sx
		local sh = math.max(y1, y2, y3, y4) - sy
		psx, psy, psw, psh = love.graphics.getScissor()
		love.graphics.intersectScissor(sx, sy, sw, sh)
	end

	for _, p in ipairs(pieces) do
		love.graphics.push()
		love.graphics.translate(p.x * ts, p.y * ts)
		love.graphics.rotate(p.facing or 0)
		paint_shape(p, ts)
		love.graphics.pop()
	end

	if love.graphics.setScissor then
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
	if love.graphics.setColor then love.graphics.setColor(cr, cg, cb, ca) end
end

function M.draw_pass()
	M.update(math.min(0.05, love.timer.getDelta()))
	M.draw()
end

return M
