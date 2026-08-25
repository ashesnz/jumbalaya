--[[
	word_game/ui/comic_burst.lua - Comic starburst behind score popups.

	Drawn with love.graphics.polygon / circle only: yellow fill, red outline,
	drop shadow, radiating action shards, and a couple of halftone clusters.

	`ComicBurst.make` / `advance` / `paint` are the shared geometry API (card
	EaseNode and the TO GO banner both use it).
]]

local ComicBurst = EaseNode:derive("ComicBurst")

local YELLOW = { 1.00, 0.90, 0.12, 1 }
local RED = { 0.90, 0.10, 0.16, 1 }
local SHADOW = { 0.05, 0.04, 0.07, 0.88 }
local INK = { 0.07, 0.05, 0.08, 1 }
local DOT = { 0.08, 0.06, 0.09, 0.55 }

local function make_rng(seed)
	seed = math.floor(seed) % 2147483647
	if seed <= 0 then seed = 1 end
	return function()
		seed = (seed * 1103515245 + 12345) % 2147483648
		return seed / 2147483648
	end
end

local function scale_verts(src, s, ox, oy)
	ox, oy = ox or 0, oy or 0
	local out = {}
	for i = 1, #src, 2 do
		out[i] = src[i] * s + ox
		out[i + 1] = src[i + 1] * s + oy
	end
	return out
end

local function star_verts(rng, n, r_in, r_out, sx, sy)
	n = n or 14
	local verts = {}
	local rot = (rng() - 0.5) * 0.35
	for i = 0, n - 1 do
		local a = (i / n) * math.pi * 2 + rot
		local long = (i % 2 == 0)
		local jitter = rng()
		local r
		if long then
			r = r_out * (0.78 + 0.22 * jitter)
			if jitter > 0.72 then
				r = r * 1.14
			end
		else
			r = r_in * (0.86 + 0.18 * jitter)
		end
		verts[#verts + 1] = math.cos(a) * r * sx
		verts[#verts + 1] = math.sin(a) * r * sy
	end
	return verts
end

local function shard_verts(angle, inner, outer, half_w)
	local c, s = math.cos(angle), math.sin(angle)
	local px, py = -s, c
	local mid = inner + (outer - inner) * 0.22
	return {
		c * inner + px * half_w * 0.15, s * inner + py * half_w * 0.15,
		c * mid + px * half_w, s * mid + py * half_w,
		c * outer, s * outer,
		c * mid - px * half_w, s * mid - py * half_w,
		c * inner - px * half_w * 0.15, s * inner - py * half_w * 0.15,
	}
end

local function build_shards(rng, r_out)
	local shards = {}
	local clusters = {
		{ angle = 0.04, count = 4, spread = 0.38, inner = 0.92, outer = 1.55 },
		{ angle = math.pi - 0.06, count = 4, spread = 0.40, inner = 0.90, outer = 1.58 },
		{ angle = -0.62, count = 2, spread = 0.18, inner = 0.88, outer = 1.28 },
		{ angle = math.pi + 0.55, count = 2, spread = 0.16, inner = 0.86, outer = 1.24 },
		{ angle = math.pi * 0.52, count = 2, spread = 0.22, inner = 0.78, outer = 1.12 },
		{ angle = -math.pi * 0.48, count = 2, spread = 0.20, inner = 0.80, outer = 1.16 },
	}
	for _, cluster in ipairs(clusters) do
		for i = 1, cluster.count do
			local t = (i - 0.5) / cluster.count - 0.5
			local a = cluster.angle + t * cluster.spread + (rng() - 0.5) * 0.08
			local inner = r_out * cluster.inner * (0.92 + 0.1 * rng())
			local outer = r_out * cluster.outer * (0.90 + 0.16 * rng())
			local hw = 0.018 + rng() * 0.022
			shards[#shards + 1] = shard_verts(a, inner, outer, hw)
		end
	end
	return shards
end

local function build_dots(rng, r_out, sx, sy)
	local dots = {}
	local clusters = {
		{ x = 0.02 * r_out, y = -0.38 * r_out, rx = 0.42 * r_out, ry = 0.18 * r_out },
		{ x = -0.04 * r_out, y = 0.40 * r_out, rx = 0.40 * r_out, ry = 0.16 * r_out },
	}
	for _, c in ipairs(clusters) do
		local cols, rows = 7, 4
		for iy = 0, rows - 1 do
			for ix = 0, cols - 1 do
				local u = (ix + 0.5) / cols * 2 - 1
				local v = (iy + 0.5) / rows * 2 - 1
				local nx, ny = u * c.rx, v * c.ry
				local d = math.sqrt((nx / c.rx) ^ 2 + (ny / c.ry) ^ 2)
				if d < 1 and rng() > 0.18 then
					local fall = 1 - d
					dots[#dots + 1] = {
						x = (c.x + nx) * sx,
						y = (c.y + ny) * sy,
						r = (0.010 + 0.016 * fall) * (0.7 + 0.4 * rng()),
					}
				end
			end
		end
	end
	return dots
end

local function pop_scale(age)
	if age < 0.07 then
		local u = age / 0.07
		return u * u * (3 - 2 * u) * 1.18
	elseif age < 0.16 then
		local u = (age - 0.07) / 0.09
		u = u * u * (3 - 2 * u)
		return 1.18 + (1.0 - 1.18) * u
	end
	return 1.0 + 0.018 * math.sin((G.TIMERS.REAL or 0) * 9)
end

function ComicBurst.make(radius)
	radius = radius or 1
	local rng = make_rng((G.TIMERS.TOTAL or 0) * 10000 + math.random(1, 99999))
	return {
		alpha = 1,
		age = 0,
		pop = 0,
		radius = radius,
		star = star_verts(rng, 14, radius * 0.46, radius, 1.22, 0.88),
		outline = nil,
		shadow = nil,
		shards = build_shards(rng, radius),
		dots = build_dots(rng, radius, 1.22, 0.88),
	}
end

local function ensure_layers(b)
	if not b.outline then
		b.outline = scale_verts(b.star, 1.13)
		b.shadow = scale_verts(b.star, 1.13, 0.055 * b.radius, 0.06 * b.radius)
	end
end

function ComicBurst.advance(b, dt)
	if not b then return end
	b.age = (b.age or 0) + (dt or 0)
	b.pop = pop_scale(b.age)
end

function ComicBurst.paint(b)
	if not b or (b.alpha or 1) <= 0 then return end
	ensure_layers(b)
	local a = b.alpha or 1
	local s = (b.pop and b.pop > 0) and b.pop or 0.001
	love.graphics.push()
	love.graphics.scale(s, s)

	love.graphics.setColor(INK[1], INK[2], INK[3], INK[4] * a)
	for _, shard in ipairs(b.shards) do
		love.graphics.polygon("fill", shard)
	end

	love.graphics.setColor(DOT[1], DOT[2], DOT[3], DOT[4] * a)
	for _, d in ipairs(b.dots) do
		love.graphics.circle("fill", d.x, d.y, d.r, 8)
	end

	love.graphics.setColor(SHADOW[1], SHADOW[2], SHADOW[3], SHADOW[4] * a)
	love.graphics.polygon("fill", b.shadow)

	love.graphics.setColor(RED[1], RED[2], RED[3], RED[4] * a)
	love.graphics.polygon("fill", b.outline)

	love.graphics.setColor(YELLOW[1], YELLOW[2], YELLOW[3], YELLOW[4] * a)
	love.graphics.polygon("fill", b.star)

	love.graphics.pop()
end

function ComicBurst:construct(X, Y, W, H, config)
	config = config or {}
	EaseNode.construct(self, X, Y, W, H)

	local data = ComicBurst.make(config.radius or 0.62)
	self.alpha = data.alpha
	self.age = data.age
	self.pop = data.pop
	self.radius = data.radius
	self.star = data.star
	self.outline = data.outline
	self.shadow = data.shadow
	self.shards = data.shards
	self.dots = data.dots

	if config.attach then
		self:set_alignment({
			major = config.attach,
			type = "cm",
			bond = "Strong",
		})
		table.insert(self.role.major.children, self)
		self.parent = self.role.major
	end

	self.states.hover.can = false
	self.states.click.can = false
	self.states.collide.can = false
	self.states.drag.can = false
	self.states.release_on.can = false
end

function ComicBurst:update(dt)
	ComicBurst.advance(self, dt)
end

function ComicBurst:draw()
	if self.alpha <= 0 then return end

	local prev_shader = love.graphics.getShader()
	local cr, cg, cb, ca = love.graphics.getColor()

	love.graphics.setShader()
	push_node_transform(self, 1)
	love.graphics.translate(self.VT.w / 2, self.VT.h / 2)
	ComicBurst.paint(self)
	love.graphics.pop()

	if prev_shader then
		love.graphics.setShader(prev_shader)
	end
	love.graphics.setColor(cr, cg, cb, ca)

	track_hit_target(self)
	self:draw_boundingrect()
end

function ComicBurst:remove()
	if self.role.major then
		for k, v in pairs(self.role.major.children) do
			if v == self and type(k) == "number" then
				table.remove(self.role.major.children, k)
			end
		end
	end
	teardown_tree(self.children)
	EaseNode.remove(self)
end

return ComicBurst
