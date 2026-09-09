--[[
	word_game/ui/stage_label.lua - Set-hand label above the timeline timer.

	Displays "1-1" style stage markers with odometer digit rolls on hand advance.
]]

local round_config = require("word_game.config.round_config")

local M = {}

local FONT_FILE = "resources/fonts/Outfit-Bold.ttf"
local ROLL_TIME = 0.38
local font_cache = {}

M.left_count = 1
M.right_count = 1
M.left_roll = nil
M.right_roll = nil
local pending_roll = nil

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

local function label_font(px)
	px = math.max(10, math.floor(px + 0.5))
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

local function game_set()
	local wr = G.GAME and G.GAME.word_round
	return wr and wr.set or 1
end

local function game_hand()
	local wr = G.GAME and G.GAME.word_round
	return wr and wr.hand_index or 1
end

local function next_set_and_hand(set, hand)
	local hands = round_config.hands_in_set(set)
	if hand >= hands then
		if set >= round_config.SETS_TO_WIN then
			return nil
		end
		return set + 1, 1
	end
	return set, hand + 1
end

local function apply_pending_roll()
	local pending = pending_roll
	if not pending then return end
	local left_roll, left_count = begin_roll(pending.from_set, pending.to_set)
	local right_roll, right_count = begin_roll(pending.from_hand, pending.to_hand)
	M.left_roll = left_roll
	M.right_roll = right_roll
	if left_count then M.left_count = left_count end
	if right_count then M.right_count = right_count end
	pending_roll = nil
end

function M.sync()
	if M.left_roll or M.right_roll then return end
	M.left_count = game_set()
	M.right_count = game_hand()
	pending_roll = nil
end

function M.force_sync()
	pending_roll = nil
	M.left_roll = nil
	M.right_roll = nil
	M.left_count = game_set()
	M.right_count = game_hand()
end

function M.reset()
	M.force_sync()
end

function M.roll_to_next_hand()
	local from_set = game_set()
	local from_hand = game_hand()
	local to_set, to_hand = next_set_and_hand(from_set, from_hand)
	if not to_set then return end
	pending_roll = {
		from_set = from_set,
		from_hand = from_hand,
		to_set = to_set,
		to_hand = to_hand,
	}
	apply_pending_roll()
end

function M.update(dt)
	dt = dt or 0
	local left_roll, left_done = tick_roll(M.left_roll, dt)
	M.left_roll = left_roll
	if left_done then M.left_count = left_done end
	local right_roll, right_done = tick_roll(M.right_roll, dt)
	M.right_roll = right_roll
	if right_done then M.right_count = right_done end
end

local function print_shadow(font, text, x, y, scale, col)
	love.graphics.setFont(font)
	love.graphics.setColor(0.04, 0.06, 0.12, 0.90)
	for ox = -1.5, 1.5, 1.5 do
		for oy = -1.5, 1.5, 1.5 do
			if ox ~= 0 or oy ~= 0 then
				love.graphics.print(text, x + ox, y + oy, 0, scale, scale)
			end
		end
	end
	love.graphics.setColor(0.02, 0.03, 0.06, 0.85)
	love.graphics.print(text, x + 1.5, y + 2.0, 0, scale, scale)
	love.graphics.setColor(col[1], col[2], col[3], col[4] or 1)
	love.graphics.print(text, x, y, 0, scale, scale)
end

local function draw_rolling_digit(font, x, y, slot_w, digit_h, scale, from, to, rolling, roll_t, colour)
	local function print_num(text, py)
		local tw = font:getWidth(text) * scale
		print_shadow(font, text, x + (slot_w - tw) * 0.5, py, scale, colour)
	end
	if love.graphics.transformPoint and love.graphics.intersectScissor and love.graphics.getScissor and love.graphics.setScissor then
		local x1, y1 = love.graphics.transformPoint(x, y)
		local x2, y2 = love.graphics.transformPoint(x + slot_w, y)
		local x3, y3 = love.graphics.transformPoint(x, y + digit_h)
		local x4, y4 = love.graphics.transformPoint(x + slot_w, y + digit_h)
		local sx = math.min(x1, x2, x3, x4)
		local sy = math.min(y1, y2, y3, y4)
		local sw = math.max(x1, x2, x3, x4) - sx
		local sh = math.max(y1, y2, y3, y4) - sy
		local psx, psy, psw, psh = love.graphics.getScissor()
		love.graphics.intersectScissor(sx, sy, sw, sh)
		if rolling then
			print_num(tostring(from), y - roll_t * digit_h)
			print_num(tostring(to), y + (1 - roll_t) * digit_h)
		else
			print_num(tostring(from), y)
		end
		if psx then
			love.graphics.setScissor(psx, psy, psw, psh)
		else
			love.graphics.setScissor()
		end
	else
		if rolling then
			print_num(tostring(from), y - roll_t * digit_h)
			print_num(tostring(to), y + (1 - roll_t) * digit_h)
		else
			print_num(tostring(from), y)
		end
	end
end

function M.draw_above_timer(x, y, w, h)
	if not love or not love.graphics then return end

	local label_h = math.max(18, h * 0.72)
	local gap = math.max(4, h * 0.14)
	local digit_h = label_h
	local font_px = math.max(18, label_h * 0.92)
	local font = label_font(font_px)
	if not font then return end

	local scale = digit_h / font:getHeight()
	local slot_w = math.max(font:getWidth("0"), font:getWidth("8")) * scale
	local dash_w = font:getWidth("-") * scale
	local gap_w = slot_w * 0.16
	local total_w = slot_w + gap_w + dash_w + gap_w + slot_w
	local cx = x + (w - total_w) * 0.5
	local digit_y = y - gap - digit_h

	local colour = (G and G.C and G.C.GOLD) or { 1, 0.85, 0.35, 1 }

	local lf, lt, lrt, lroll = roll_view(M.left_roll, M.left_count or 1)
	local rf, rt, rrt, rroll = roll_view(M.right_roll, M.right_count or 1)

	draw_rolling_digit(font, cx, digit_y, slot_w, digit_h, scale, lf, lt, lroll, lrt, colour)
	local dash_x = cx + slot_w + gap_w
	print_shadow(font, "-", dash_x, digit_y, scale, colour)
	local right_x = dash_x + dash_w + gap_w
	draw_rolling_digit(font, right_x, digit_y, slot_w, digit_h, scale, rf, rt, rroll, rrt, colour)
end

return M
