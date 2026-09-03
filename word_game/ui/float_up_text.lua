--[[
	word_game/ui/float_up_text.lua - Steam-rise score text.

	Dice Have No Eyes float_up_text: spawn on the die, drift up, fade out.
	Here it emits from a played card (or the play row) and wobbles like steam.
]]

local FloatUpText = EaseNode:derive("FloatUpText")

local FONT_FILE = "resources/fonts/Outfit-Bold.ttf"
local font_cache = {}
local live = {}

local DEFAULT_COLOUR = { 0.0, 1.0, 0.965, 1 }
local SHADOW = { 0.07, 0.05, 0.08, 0.9 }
local CARD_BONUS_START_OFFSET = 0.65
local CARD_ABOVE_GAP = 0.14

local function title_font(px)
	px = math.max(10, math.floor(px + 0.5))
	local cached = font_cache[px]
	if cached then return cached end
	local ok, font = pcall(love.graphics.newFont, FONT_FILE, px)
	if not ok or not font then
		font = love.graphics.newFont(px)
	end
	font:setFilter("linear", "linear")
	font_cache[px] = font
	return font
end

function FloatUpText:construct(config)
	config = config or {}
	local w = config.w or 1.4
	local h = config.h or 0.55
	EaseNode.construct(self, config.x or 0, config.y or 0, w, h)
	self:set_container(G.ROOM)
	self.states.hover.can = false
	self.states.click.can = false
	self.states.collide.can = false
	self.states.drag.can = false
	self.states.release_on.can = false

	self.text = config.text or "+2"
	self.colour = config.colour or DEFAULT_COLOUR
	self.life = config.life or 1.55
	self.age = 0
	self.speed = config.speed or 1.35
	self.wobble = config.wobble or 0.07
	self.phase = (config.phase or love.math.random()) * math.pi * 2
	self.origin_x = self.T.x
	self.font_px = config.font_px or 28
	self.alpha = 1

	self:hard_set_T(self.T.x, self.T.y, self.T.w, self.T.h)
	self:snap_VT()
	live[#live + 1] = self
end

function FloatUpText:update(dt)
	dt = dt or 0
	self.age = self.age + dt
	local t = self.age
	local slow = 1.12 - 0.55 * math.min(1, t / (self.life * 0.7))
	self.T.y = self.T.y - self.speed * dt * slow
	self.T.x = self.origin_x + math.sin(t * 6.4 + self.phase) * self.wobble
		+ math.sin(t * 11.0 + self.phase * 0.4) * self.wobble * 0.28
	self.VT.x = self.T.x
	self.VT.y = self.T.y

	local fade_start = self.life * 0.38
	if t <= fade_start then
		self.alpha = 1
	else
		self.alpha = math.max(0, 1 - (t - fade_start) / (self.life - fade_start))
	end
	if t >= self.life or self.alpha <= 0 then
		self:remove()
	end
end

function FloatUpText:draw()
	if not self.states.visible or (self.alpha or 1) <= 0 then return end
	if not G.ROOM then return end

	local ts = G.TILESCALE * G.TILESIZE
	local font = title_font(self.font_px)
	local txt = self.text
	local w = self.VT.w * ts
	local x = self.VT.x * ts
	local y = self.VT.y * ts
	local a = self.alpha
	local c = self.colour
	local prev_font = love.graphics.getFont()
	local cr, cg, cb, ca = love.graphics.getColor()
	local prev_shader = love.graphics.getShader()

	love.graphics.push()
	love.graphics.setShader()
	self:translate_container()
	love.graphics.setFont(font)
	love.graphics.setColor(SHADOW[1], SHADOW[2], SHADOW[3], SHADOW[4] * a)
	love.graphics.printf(txt, x + 2, y + 2, w, "center")
	love.graphics.setColor(c[1], c[2], c[3], (c[4] or 1) * a)
	love.graphics.printf(txt, x, y, w, "center")
	love.graphics.pop()

	if prev_shader then
		love.graphics.setShader(prev_shader)
	else
		love.graphics.setShader()
	end
	if prev_font then love.graphics.setFont(prev_font) end
	love.graphics.setColor(cr, cg, cb, ca)
end

function FloatUpText:remove()
	for i = #live, 1, -1 do
		if live[i] == self then
			table.remove(live, i)
			break
		end
	end
	EaseNode.remove(self)
end

function FloatUpText.spawn(config)
	if not G.ROOM then return nil end
	return FloatUpText(config)
end

function FloatUpText.from_timeline(text, opts)
	opts = opts or {}
	local Layout = require("word_game.ui.layout")
	local rect = Layout.timeline_rect and Layout.timeline_rect() or { x = 0, y = 0, w = 4, h = 0.7 }
	local w = opts.w or 1.2
	local h = opts.h or 0.55
	return FloatUpText.spawn({
		x = rect.x + rect.w * 0.5 - w * 0.5,
		y = rect.y - h * 0.55,
		w = w,
		h = h,
		text = text,
		colour = opts.colour,
		life = opts.life or 1.35,
		speed = opts.speed or 1.1,
		wobble = opts.wobble or 0.05,
		font_px = opts.font_px or 30,
	})
end

function FloatUpText.card_layout_rect(card)
	if not card or not card.T then return nil end
	local t = card.T
	return t.x, t.y, t.w, t.h
end

function FloatUpText.from_card_above(card, text, opts)
	opts = opts or {}
	local cx, cy, cw, ch = FloatUpText.card_layout_rect(card)
	if not cx then return nil end
	local w = opts.w or 1.5
	local h = opts.h or 0.5
	local gap = opts.above_gap or CARD_ABOVE_GAP
	return FloatUpText.spawn({
		x = cx + cw * 0.5 - w * 0.5,
		y = cy - h - gap,
		w = w,
		h = h,
		text = text,
		colour = opts.colour,
		life = opts.life,
		speed = opts.speed,
		wobble = opts.wobble,
		font_px = opts.font_px,
	})
end

function FloatUpText.from_card(card, text, opts)
	opts = opts or {}
	if not card or not card.T then return nil end
	local w = opts.w or 1.5
	local h = opts.h or 0.5
	return FloatUpText.spawn({
		x = card.T.x + card.T.w * 0.5 - w * 0.5,
		y = card.T.y + card.T.h * 0.08 + CARD_BONUS_START_OFFSET,
		w = w,
		h = h,
		text = text,
		colour = opts.colour,
		life = opts.life,
		speed = opts.speed,
		wobble = opts.wobble,
		font_px = opts.font_px,
	})
end

function FloatUpText.from_cards(cards, text, opts)
	opts = opts or {}
	if not cards or #cards == 0 then return nil end
	local min_x, max_x, min_y = nil, nil, nil
	for _, card in ipairs(cards) do
		if card and card.T then
			local left = card.T.x
			local right = card.T.x + card.T.w
			local top = card.T.y
			min_x = min_x and math.min(min_x, left) or left
			max_x = max_x and math.max(max_x, right) or right
			min_y = min_y and math.min(min_y, top) or top
		end
	end
	if not min_x then return nil end
	local w = opts.w or 2.4
	local h = opts.h or 0.85
	return FloatUpText.spawn({
		x = (min_x + max_x) * 0.5 - w * 0.5,
		y = min_y - h * 0.15,
		w = w,
		h = h,
		text = text,
		colour = opts.colour,
		life = opts.life,
		speed = opts.speed,
		wobble = opts.wobble,
		font_px = opts.font_px,
	})
end

function FloatUpText.update_all(dt)
	for i = #live, 1, -1 do
		local item = live[i]
		if item and not item.REMOVED then
			item:update(dt)
		end
	end
end

function FloatUpText.draw_pass()
	local dt = math.min(0.05, love.timer.getDelta())
	FloatUpText.update_all(dt)
	for _, item in ipairs(live) do
		if item and not item.REMOVED then
			item:draw()
		end
	end
end

function FloatUpText.clear()
	for i = #live, 1, -1 do
		local item = live[i]
		if item and item.remove then
			item:remove()
		end
	end
end

return FloatUpText
