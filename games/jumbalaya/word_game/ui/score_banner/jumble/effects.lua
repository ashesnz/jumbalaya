--[[ word_game/ui/score_banner/jumble/effects.lua - Bounce, spin, burst, layout math ]]

local game = require("word_game.ui.util.game_runtime").game
local Layout = require("word_game.ui.layout")
local fonts = require("word_game.ui.score_banner.fonts")
local config = require("word_game.ui.score_banner.jumble.config")
local ComicBurst = require("word_game.ui.feedback.comic_burst")

local M = {}


local function clamp01(t)
	if t < 0 then return 0 end
	if t > 1 then return 1 end
	return t
end

function M.trigger_points_bounce(state, amp)
	state.points_bounce = { t = 0, dur = config.BOUNCE_DUR, amp = amp or 1.0 }
end

function M.trigger_multi_bounce(state, amp)
	state.multi_bounce = { t = 0, dur = config.BOUNCE_DUR, amp = amp or 1.0 }
end

function M.trigger_points_spin(state)
	local start_box = state.points_rot or 0
	local rot_delta = 4 * math.pi + math.pi / 4
	state.points_spin = {
		t = 0,
		dur = config.SPIN_DUR,
		start_box = start_box,
		target_box = start_box + rot_delta,
		rot_delta = rot_delta,
		digit_spin = 4 * math.pi,
	}
	state.points_burst = ComicBurst.make(1)
end

function M.trigger_multi_spin(state)
	local start_box = state.multi_rot or 0
	local rot_delta = -(4 * math.pi + math.pi / 4)
	state.multi_spin = {
		t = 0,
		dur = config.SPIN_DUR,
		start_box = start_box,
		target_box = start_box + rot_delta,
		rot_delta = rot_delta,
		digit_spin = -(4 * math.pi),
	}
	state.multi_burst = ComicBurst.make(1)
end

local function ease_out_spin(u)
	u = math.max(0, math.min(1, u))
	local inv = 1 - u
	return 1 - inv * inv * inv * (1 + 0.15 * math.sin(u * math.pi))
end

function M.calc_box_rotation(spin_obj, default_rot)
	if not spin_obj or not spin_obj.dur or spin_obj.dur <= 0 then
		return default_rot or 0
	end
	local u = clamp01(spin_obj.t / spin_obj.dur)
	local ease = ease_out_spin(u)
	return spin_obj.start_box + spin_obj.rot_delta * ease
end

function M.calc_digit_rotation(spin_obj)
	if not spin_obj or not spin_obj.dur or spin_obj.dur <= 0 then
		return 0
	end
	local u = clamp01(spin_obj.t / spin_obj.dur)
	local ease = ease_out_spin(u)
	return spin_obj.digit_spin * ease
end

function M.calc_layout(w, h, slant)
	local inner_w = (w or 400) - (slant or 0) * 2
	local box_size = math.min((h or 60) * 1.68, inner_w * 0.44)
	local num_font_px = math.max(28, math.floor(box_size * 0.65))
	local x_font_px = math.max(24, math.floor(box_size * 0.55))
	local font_x = fonts.bubble_font(x_font_px)
	local x_tw = font_x:getWidth("X")
	local gap = math.max(12, math.floor(box_size * 0.16))

	local chip_cx = -box_size * 0.5 - gap - x_tw * 0.5
	local mult_cx = box_size * 0.5 + gap + x_tw * 0.5
	local radius = math.max(6, box_size * 0.18)

	return {
		box_size = box_size,
		num_font_px = num_font_px,
		x_font_px = x_font_px,
		x_tw = x_tw,
		gap = gap,
		chip_cx = chip_cx,
		mult_cx = mult_cx,
		radius = radius,
	}
end

function M.calc_bounce(bounce_obj)
	if not bounce_obj or not bounce_obj.dur or bounce_obj.dur <= 0 then
		return 1.0, 1.0, 0
	end
	local u = clamp01(bounce_obj.t / bounce_obj.dur)
	local amp = bounce_obj.amp or 1.0
	local envelope = math.sin(u * math.pi) * (1.0 - u * 0.35)
	local osc = math.sin(u * math.pi * 3.2) * math.exp(-u * 3.8)
	local scale_fac = 1.0 + (envelope * 0.28 + osc * 0.10) * amp
	local intensity = envelope * amp
	return scale_fac, scale_fac, intensity
end

function M.get_multi_growth(cur_multi)
	cur_multi = cur_multi or 1.0
	local step = math.max(0, cur_multi - 1.0)
	return 1.0 + math.min(0.28, step * 0.18)
end

function M.calc_points_to_get_pos(cx, ts)
	ts = ts or ((game() and game().TILESCALE or 1) * (game() and game().TILESIZE or 1))
	local area = game() and game().pattern_row and game().pattern_row.area
	local felt = Layout.felt_rect()
	local card_bottom = (area and area.T and area.T.y and area.T.h)
		and ((area.T.y + area.T.h) * ts)
		or ((felt.y + 2.0) * ts)
	local hand_top = (game() and game().dealt_letters and game().dealt_letters.T and game().dealt_letters.T.y)
		and (game().dealt_letters.T.y * ts)
		or ((felt.y + felt.h - 2.5) * ts)
	local gap_cy = (card_bottom + hand_top) * 0.5 - ts * config.POINTS_TO_GET_RAISE
	return cx or ((felt.x + felt.w * 0.5) * ts), gap_cy
end

return M
