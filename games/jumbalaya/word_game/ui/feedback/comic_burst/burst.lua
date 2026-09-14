--[[ word_game/ui/feedback/comic_burst/burst.lua - Burst state, pop envelope, paint ]]

local GameRT = require("word_game.ui.util.game_runtime")
local config = require("word_game.ui.feedback.comic_burst.config")
local geometry = require("word_game.ui.feedback.comic_burst.geometry")

local M = {}

local function runtime()
	return GameRT.game()
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
	return 1.0 + 0.018 * math.sin((runtime().TIMERS.REAL or 0) * 9)
end

function M.make(radius)
	radius = radius or 1
	local rng = geometry.make_rng((runtime().TIMERS.TOTAL or 0) * 10000 + math.random(1, 99999))
	return {
		alpha = 1,
		age = 0,
		pop = 0,
		radius = radius,
		star = geometry.star_verts(rng, 14, radius * 0.46, radius, 1.22, 0.88),
		outline = nil,
		shadow = nil,
		shards = geometry.build_shards(rng, radius),
		dots = geometry.build_dots(rng, radius, 1.22, 0.88),
	}
end

local function ensure_layers(b)
	if not b.outline then
		b.outline = geometry.scale_verts(b.star, 1.13)
		b.shadow = geometry.scale_verts(b.star, 1.13, 0.055 * b.radius, 0.06 * b.radius)
	end
end

function M.advance(b, dt)
	if not b then return end
	b.age = (b.age or 0) + (dt or 0)
	b.pop = pop_scale(b.age)
end

function M.paint(b)
	if not b or (b.alpha or 1) <= 0 then return end
	ensure_layers(b)
	local a = b.alpha or 1
	local s = (b.pop and b.pop > 0) and b.pop or 0.001
	love.graphics.push()
	love.graphics.scale(s, s)

	love.graphics.setColor(config.INK[1], config.INK[2], config.INK[3], config.INK[4] * a)
	for _, shard in ipairs(b.shards) do
		love.graphics.polygon("fill", shard)
	end

	love.graphics.setColor(config.DOT[1], config.DOT[2], config.DOT[3], config.DOT[4] * a)
	for _, d in ipairs(b.dots) do
		love.graphics.circle("fill", d.x, d.y, d.r, 8)
	end

	love.graphics.setColor(config.SHADOW[1], config.SHADOW[2], config.SHADOW[3], config.SHADOW[4] * a)
	love.graphics.polygon("fill", b.shadow)

	love.graphics.setColor(config.RED[1], config.RED[2], config.RED[3], config.RED[4] * a)
	love.graphics.polygon("fill", b.outline)

	love.graphics.setColor(config.YELLOW[1], config.YELLOW[2], config.YELLOW[3], config.YELLOW[4] * a)
	love.graphics.polygon("fill", b.star)

	love.graphics.pop()
end

return M
