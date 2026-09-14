--[[ word_game/ui/score_banner/draw/helpers.lua - Room transform and rolling digits ]]

local game = require("word_game.ui.util.game_runtime").game
local Roll = require("jumbalaya-engine.util.roll")

local M = {}


function M.ease_inout(t)
	t = Roll.clamp01(t)
	return t * t * (3 - 2 * t)
end

function M.room_translate()
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

function M.draw_rolling_digit(cx, cy, from_val, to_val, roll, font, scale, col, box_w, box_h, is_float)
	local fh = font:getHeight() * scale
	local slot_h = box_h * 0.85
	local digit_y = cy - fh * 0.5

	local format_val = function(v)
		if is_float then
			return string.format("%.1f", v or 1.0)
		else
			return tostring(math.floor((v or 0) + 0.5))
		end
	end

	local from_str = format_val(from_val)
	local to_str = format_val(to_val)

	local psx, psy, psw, psh = nil, nil, nil, nil
	if love.graphics.transformPoint and love.graphics.intersectScissor and love.graphics.getScissor and love.graphics.setScissor then
		local x1, y1 = love.graphics.transformPoint(cx - box_w * 0.5, cy - box_h * 0.5)
		local x2, y2 = love.graphics.transformPoint(cx + box_w * 0.5, cy - box_h * 0.5)
		local x3, y3 = love.graphics.transformPoint(cx - box_w * 0.5, cy + box_h * 0.5)
		local x4, y4 = love.graphics.transformPoint(cx + box_w * 0.5, cy + box_h * 0.5)
		local sx = math.min(x1, x2, x3, x4)
		local sy = math.min(y1, y2, y3, y4)
		local sw = math.max(x1, x2, x3, x4) - sx
		local sh = math.max(y1, y2, y3, y4) - sy

		psx, psy, psw, psh = love.graphics.getScissor()
		love.graphics.intersectScissor(sx, sy, sw, sh)
	end

	local function print_str(str, y_off)
		local tw = font:getWidth(str) * scale
		local px = cx - tw * 0.5
		local py = digit_y + y_off
		if love.graphics.setColor then love.graphics.setColor(0, 0, 0, 0.6) end
		if love.graphics.print then love.graphics.print(str, px + 1.5, py + 1.5, 0, scale, scale) end
		if love.graphics.setColor then love.graphics.setColor(col[1], col[2], col[3], col[4] or 1) end
		if love.graphics.print then love.graphics.print(str, px, py, 0, scale, scale) end
	end

	if roll and roll.dur and roll.dur > 0 then
		local ease = Roll.ease_out(roll.t / roll.dur)
		print_str(from_str, -ease * slot_h)
		print_str(to_str, (1 - ease) * slot_h)
	else
		print_str(to_str, 0)
	end

	if love.graphics.setScissor then
		if psx then
			love.graphics.setScissor(psx, psy, psw, psh)
		else
			love.graphics.setScissor()
		end
	end
end

return M
