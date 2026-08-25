--[[
	word_game/ui/odometer.lua - Rolling digit + label, same motion as the bin count.
]]

local Odometer = EaseNode:derive("Odometer")

local FONT_FILE = "resources/fonts/Outfit-Bold.ttf"
local ROLL_TIME = 0.38
local font_cache = {}

local function clamp01(t)
	if t < 0 then return 0 end
	if t > 1 then return 1 end
	return t
end

local function ease_out(t)
	t = clamp01(t)
	local inv = 1 - t
	return 1 - inv * inv * inv
end

local function meter_font(px)
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

local function begin_roll(from, to)
	if from == to then
		return nil, to
	end
	return { from = from, to = to, t = 0, dur = ROLL_TIME }, from
end

local function tick_roll(roll, dt)
	if not roll then return nil, nil end
	roll.t = roll.t + dt
	if roll.t >= roll.dur then
		return nil, roll.to
	end
	return roll, nil
end

local function roll_view(roll, fallback)
	if not roll then
		return fallback, fallback, 1, false
	end
	return roll.from, roll.to, ease_out(roll.t / roll.dur), true
end

function Odometer:construct(config)
	config = config or {}
	self.label = config.label or "Plays Left"
	self.colour = config.colour or G.C.RED
	self.label_colour = config.label_colour or (G.C.UI and G.C.UI.TEXT_LIGHT) or { 1, 1, 1, 1 }
	self.label_on_top = config.label_on_top
	self.value_fn = config.value_fn
	self.display_count = config.value or (self.value_fn and self.value_fn()) or 0
	self.roll = nil
	self.pair = config.pair
	self.subtitle_fn = config.subtitle_fn
	self.subtitle_colour = config.subtitle_colour or G.C.RED
	self.config = config

	if self.pair then
		self.left_count = config.left or 1
		self.right_count = config.right or 1
		self.left_roll = nil
		self.right_roll = nil
	end

	local w = config.w or 2.6
	local h = config.h or 1.25
	EaseNode.construct(self, 0, 0, w, h)
	self.states.hover.can = false
	self.states.click.can = false
	self.states.collide.can = false
	self.states.drag.can = false
	self:set_role{
		wh_bond = "Weak",
		scale_bond = "Weak",
	}
	if getmetatable(self) == Odometer then
		table.insert(G.LIVE.TRANSFORM, self)
	end
end

function Odometer:current_value()
	if self.value_fn then
		return self.value_fn()
	end
	return self.display_count or 0
end

function Odometer:start_roll(from, to)
	from = from or self.display_count or 0
	to = to or from
	local roll, count = begin_roll(from, to)
	self.roll = roll
	if count then self.display_count = count end
end

function Odometer:start_pair_roll(from_left, from_right, to_left, to_right)
	from_left = from_left or self.left_count or 1
	from_right = from_right or self.right_count or 1
	to_left = to_left or from_left
	to_right = to_right or from_right
	local left_roll, left_count = begin_roll(from_left, to_left)
	local right_roll, right_count = begin_roll(from_right, to_right)
	self.left_roll = left_roll
	self.right_roll = right_roll
	if left_count then self.left_count = left_count end
	if right_count then self.right_count = right_count end
end

function Odometer:displayed_right()
	if self.right_roll then
		return self.right_roll.to
	end
	return self.right_count or 1
end

function Odometer:update(dt)
	dt = dt or 0
	if self.pair then
		local left_roll, left_done = tick_roll(self.left_roll, dt)
		self.left_roll = left_roll
		if left_done then self.left_count = left_done end
		local right_roll, right_done = tick_roll(self.right_roll, dt)
		self.right_roll = right_roll
		if right_done then self.right_count = right_done end
		return
	end

	local actual = self:current_value()
	if self.roll then
		local roll, done = tick_roll(self.roll, dt)
		self.roll = roll
		if done then self.display_count = done end
	elseif self.display_count ~= actual then
		if actual > (self.display_count or 0) or math.abs(actual - (self.display_count or 0)) > 1 then
			self.display_count = actual
		end
	end
end

function Odometer:draw()
	if not self.states.visible then return end

	local w, h = self.VT.w, self.VT.h
	push_node_transform(self, 1)

	local num_px = math.max(28, h * (self.pair and 36 or 42))
	local label_px = math.max(12, h * (self.pair and 12 or 14))
	local num_font = meter_font(num_px)
	local label_font = meter_font(label_px)
	local num_h = h * (self.pair and 0.48 or 0.62)
	local label_h = h * (self.pair and 0.22 or 0.28)
	local num_scale = num_h / num_font:getHeight()
	local label_scale = label_h / label_font:getHeight()
	local slot_w = math.max(num_font:getWidth("0"), num_font:getWidth("8")) * num_scale
	local label_w = label_font:getWidth(self.label) * label_scale
	if label_w > w * 0.96 then
		label_scale = label_scale * (w * 0.96 / label_w)
		label_h = label_font:getHeight() * label_scale
		label_w = label_font:getWidth(self.label) * label_scale
	end

	local digit_y, label_x, label_y
	label_x = (w - label_w) * 0.5
	if self.label_on_top then
		label_y = h * 0.02
		digit_y = label_y + label_h + h * 0.02
	else
		digit_y = h * 0.04
		label_y = digit_y + num_h + h * 0.04
	end

	local prev_font = love.graphics.getFont()
	local function print_shadow(font, text, x, y, scale, col)
		love.graphics.setFont(font)
		love.graphics.setColor(0, 0, 0, 0.65)
		love.graphics.print(text, x + 0.02, y + 0.025, 0, scale, scale)
		love.graphics.setColor(col[1], col[2], col[3], col[4] or 1)
		love.graphics.print(text, x, y, 0, scale, scale)
	end

	local function draw_rolling_digit(x, from, to, rolling, roll_t)
		local function print_num(text, y)
			local tw = num_font:getWidth(text) * num_scale
			print_shadow(num_font, text, x + (slot_w - tw) * 0.5, y, num_scale, self.colour)
		end
		if love.graphics.transformPoint and love.graphics.intersectScissor and love.graphics.getScissor and love.graphics.setScissor then
			local x1, y1 = love.graphics.transformPoint(x, digit_y)
			local x2, y2 = love.graphics.transformPoint(x + slot_w, digit_y)
			local x3, y3 = love.graphics.transformPoint(x, digit_y + num_h)
			local x4, y4 = love.graphics.transformPoint(x + slot_w, digit_y + num_h)
			local sx = math.min(x1, x2, x3, x4)
			local sy = math.min(y1, y2, y3, y4)
			local sw = math.max(x1, x2, x3, x4) - sx
			local sh = math.max(y1, y2, y3, y4) - sy
			local psx, psy, psw, psh = love.graphics.getScissor()
			love.graphics.intersectScissor(sx, sy, sw, sh)
			if rolling then
				print_num(tostring(from), digit_y - roll_t * num_h)
				print_num(tostring(to), digit_y + (1 - roll_t) * num_h)
			else
				print_num(tostring(from), digit_y)
			end
			if psx then
				love.graphics.setScissor(psx, psy, psw, psh)
			else
				love.graphics.setScissor()
			end
		else
			if rolling then
				print_num(tostring(from), digit_y - roll_t * num_h)
				print_num(tostring(to), digit_y + (1 - roll_t) * num_h)
			else
				print_num(tostring(from), digit_y)
			end
		end
	end

	if self.pair then
		local dash_w = num_font:getWidth("-") * num_scale
		local gap = slot_w * 0.18
		local total_w = slot_w + gap + dash_w + gap + slot_w
		local x0 = (w - total_w) * 0.5
		local left_x = x0
		local dash_x = x0 + slot_w + gap
		local right_x = dash_x + dash_w + gap
		local lf, lt, lrt, lroll = roll_view(self.left_roll, self.left_count or 1)
		local rf, rt, rrt, rroll = roll_view(self.right_roll, self.right_count or 1)
		draw_rolling_digit(left_x, lf, lt, lroll, lrt)
		print_shadow(num_font, "-", dash_x, digit_y, num_scale, self.colour)
		draw_rolling_digit(right_x, rf, rt, rroll, rrt)

		local subtitle = self.subtitle_fn and self.subtitle_fn(self:displayed_right())
		if subtitle and subtitle ~= "" then
			local sub_px = math.max(11, h * 11)
			local sub_font = meter_font(sub_px)
			local sub_h = h * 0.18
			local sub_scale = sub_h / sub_font:getHeight()
			local sub_w = sub_font:getWidth(subtitle) * sub_scale
			if sub_w > w * 0.96 then
				sub_scale = sub_scale * (w * 0.96 / sub_w)
				sub_w = sub_font:getWidth(subtitle) * sub_scale
			end
			local sub_x = (w - sub_w) * 0.5
			local sub_y = digit_y + num_h + h * 0.03
			print_shadow(sub_font, subtitle, sub_x, sub_y, sub_scale, self.subtitle_colour)
		end
	else
		local digit_x = (w - slot_w) * 0.5
		local from, to, roll_t, rolling = roll_view(self.roll, self.display_count or self:current_value())
		draw_rolling_digit(digit_x, from, to, rolling, roll_t)
	end

	print_shadow(label_font, self.label, label_x, label_y, label_scale, self.label_colour)

	if prev_font then love.graphics.setFont(prev_font) end
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.pop()
	track_hit_target(self)
end

return Odometer
