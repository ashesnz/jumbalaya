--[[ word_game/ui/score_banner/draw/chips.lua - Points × multiplier chip boxes ]]

local Roll = require("jumbalaya-engine.util.roll")
local ComicBurst = require("word_game.ui.feedback.comic_burst")
local fonts = require("word_game.ui.score_banner.fonts")
local helpers = require("word_game.ui.score_banner.draw.helpers")

local M = {}

local CHIP_BG = { 0.15, 0.38, 0.82, 1 }
local CHIP_BORDER = { 0.08, 0.22, 0.55, 1 }
local MULT_BG = { 0.85, 0.20, 0.25, 1 }
local MULT_BORDER = { 0.58, 0.10, 0.15, 1 }
local BOX_SHADOW = { 0.05, 0.08, 0.15, 0.35 }

local function draw_box(bg, border, bounce_amt, box_size, radius)
	love.graphics.setColor(BOX_SHADOW)
	love.graphics.rectangle("fill", -box_size * 0.5 + 3, -box_size * 0.5 + 3, box_size, box_size, radius, radius)
	love.graphics.setColor(bg)
	love.graphics.rectangle("fill", -box_size * 0.5, -box_size * 0.5, box_size, box_size, radius, radius)
	love.graphics.setLineWidth(math.max(3, box_size * 0.06))
	love.graphics.setColor(border)
	love.graphics.rectangle("line", -box_size * 0.5, -box_size * 0.5, box_size, box_size, radius, radius)
	love.graphics.setColor(1, 1, 1, 0.16 + bounce_amt * 0.20)
	love.graphics.rectangle("fill", -box_size * 0.5 + 3, -box_size * 0.5 + 3, box_size - 6, box_size * 0.38, radius * 0.7, radius * 0.7)
end

function M.draw(sb, layout, w, h)
	local box_size = layout.box_size
	local chip_cx = layout.chip_cx
	local mult_cx = layout.mult_cx
	local radius = layout.radius

	local pts_sx, pts_sy, pts_bounce_amt = sb.calc_bounce(sb.points_bounce)

	local cur_multi = sb.multi_roll
		and (sb.multi_roll.from + Roll.clamp01(sb.multi_roll.t / sb.multi_roll.dur) * (sb.multi_roll.to - sb.multi_roll.from))
		or (sb.jumble_multi or 1.0)
	local multi_growth = sb.get_multi_growth(cur_multi)
	local mult_sx, mult_sy, mult_bounce_amt = sb.calc_bounce(sb.multi_bounce)

	local pts_box_rot = sb.calc_box_rotation(sb.points_spin, sb.points_rot)
	local mult_box_rot = sb.calc_box_rotation(sb.multi_spin, sb.multi_rot)
	local pts_digit_rot = sb.calc_digit_rotation(sb.points_spin)
	local mult_digit_rot = sb.calc_digit_rotation(sb.multi_spin)

	local max_mult_scale = math.min(1.45, (h * 2.2) / box_size)
	local eff_mult_scale_x = math.min(max_mult_scale, mult_sx * multi_growth)
	local eff_mult_scale_y = math.min(max_mult_scale, mult_sy * multi_growth)
	local eff_pts_scale_x = math.min(max_mult_scale, pts_sx)
	local eff_pts_scale_y = math.min(max_mult_scale, pts_sy)

	local num_font = fonts.bubble_font(layout.num_font_px)
	local x_font = fonts.bubble_font(layout.x_font_px)

	if sb.points_burst then
		local burst_scale = math.max(box_size * 1.30, 42)
		love.graphics.push()
		love.graphics.translate(chip_cx, 0)
		love.graphics.scale(burst_scale, burst_scale * 0.85)
		ComicBurst.paint(sb.points_burst)
		love.graphics.pop()
	end

	if sb.multi_burst then
		local burst_scale = math.max(box_size * 1.30, 42)
		love.graphics.push()
		love.graphics.translate(mult_cx, 0)
		love.graphics.scale(burst_scale, burst_scale * 0.85)
		ComicBurst.paint(sb.multi_burst)
		love.graphics.pop()
	end

	love.graphics.push()
	love.graphics.translate(chip_cx, 0)
	love.graphics.scale(eff_pts_scale_x, eff_pts_scale_y)
	love.graphics.rotate(pts_box_rot)
	draw_box(CHIP_BG, CHIP_BORDER, pts_bounce_amt, box_size, radius)
	love.graphics.pop()

	love.graphics.push()
	love.graphics.translate(mult_cx, 0)
	love.graphics.scale(eff_mult_scale_x, eff_mult_scale_y)
	love.graphics.rotate(mult_box_rot)
	draw_box(MULT_BG, MULT_BORDER, mult_bounce_amt, box_size, radius)
	love.graphics.pop()

	love.graphics.push()
	love.graphics.translate(chip_cx, 0)
	love.graphics.scale(eff_pts_scale_x, eff_pts_scale_y)
	love.graphics.rotate(pts_digit_rot)
	love.graphics.setFont(num_font)
	fonts.set_score_shader(pts_bounce_amt, false)
	local from_p = sb.points_roll and sb.points_roll.from or sb.jumble_points or 0
	local to_p = sb.points_roll and sb.points_roll.to or sb.jumble_points or 0
	helpers.draw_rolling_digit(0, 0, from_p, to_p, sb.points_roll, num_font, 1, { 1, 1, 1, 1 }, box_size, box_size, false)
	fonts.reset_score_shader()
	love.graphics.pop()

	love.graphics.push()
	love.graphics.translate(mult_cx, 0)
	love.graphics.scale(eff_mult_scale_x, eff_mult_scale_y)
	love.graphics.rotate(mult_digit_rot)
	love.graphics.setFont(num_font)
	fonts.set_score_shader(mult_bounce_amt, true)
	local from_m = sb.multi_roll and sb.multi_roll.from or sb.jumble_multi or 1.0
	local to_m = sb.multi_roll and sb.multi_roll.to or sb.jumble_multi or 1.0
	helpers.draw_rolling_digit(0, 0, from_m, to_m, sb.multi_roll, num_font, 1, { 1, 1, 1, 1 }, box_size, box_size, true)
	fonts.reset_score_shader()
	love.graphics.pop()

	love.graphics.setFont(x_font)
	local x_str = "X"
	local x_tw = layout.x_tw
	local x_th = x_font:getHeight()
	love.graphics.setColor(0.10, 0.12, 0.20, 0.85)
	love.graphics.print(x_str, -x_tw * 0.5 + 2, -x_th * 0.5 + 2)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.print(x_str, -x_tw * 0.5, -x_th * 0.5)
end

return M
