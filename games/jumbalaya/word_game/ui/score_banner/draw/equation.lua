--[[ word_game/ui/score_banner/draw/equation.lua - "Points to get" equation line ]]

local Layout = require("word_game.ui.layout")
local felt_layout = require("word_game.ui.layout.felt")
local fonts = require("word_game.ui.score_banner.fonts")

local M = {}

function M.draw(sb, cx, ts, h)
	if sb.hide_points_to_get or felt_layout.is_boss_sequence() then return end

	local remaining = sb.points_to_get or 0
	local got = sb.points_got or 0
	if remaining <= 0 and got <= 0 then return end

	local to_get_txt = sb.format_score_equation and sb.format_score_equation()
		or string.format("%d Earnt + %d = %d Remaining",
			math.floor(sb.points_earned or 0), got, remaining)
	local to_get_font_px = math.max(12, math.floor(h * 0.34))
	local to_get_font = fonts.title_font(to_get_font_px)
	love.graphics.setFont(to_get_font)
	local felt_w = (Layout.felt_rect().w or 20) * ts
	local to_get_tw = to_get_font:getWidth(to_get_txt)
	while to_get_tw > felt_w * 0.94 and to_get_font_px > 10 do
		to_get_font_px = to_get_font_px - 1
		to_get_font = fonts.title_font(to_get_font_px)
		love.graphics.setFont(to_get_font)
		to_get_tw = to_get_font:getWidth(to_get_txt)
	end
	local to_get_th = to_get_font:getHeight()

	local to_get_cx, to_get_cy = sb.calc_points_to_get_pos(cx, ts)
	local to_get_tx = to_get_cx - to_get_tw * 0.5
	local to_get_ty = to_get_cy - to_get_th * 0.5

	love.graphics.setColor(0.04, 0.08, 0.16, 0.75)
	love.graphics.print(to_get_txt, to_get_tx + 1.5, to_get_ty + 1.5)
	love.graphics.setColor(0.98, 0.96, 0.90, 1)
	love.graphics.print(to_get_txt, to_get_tx, to_get_ty)
end

return M
