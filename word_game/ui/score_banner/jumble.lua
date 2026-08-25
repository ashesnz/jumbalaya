--[[
	word_game/ui/score_banner/jumble.lua - Jumble score state, rolls, and animation.
]]

local Layout = require("word_game.ui.layout")
local fonts = require("word_game.ui.score_banner.fonts")

local M = {}

M.ROLL_TIME = 0.35
M.TO_GET_ROLL_TIME = 0.40
M.BOUNCE_DUR = 0.38
M.SPIN_DUR = 0.50

M.jumble_points = 0
M.jumble_multi = 1.0
M.points_to_get = 20
M.hide_points_to_get = false
M.points_roll = nil
M.multi_roll = nil
M.to_get_roll = nil

M.points_burst = nil
M.multi_burst = nil
M.points_bounce = nil
M.multi_bounce = nil
M.points_spin = nil
M.multi_spin = nil
M.points_rot = 0
M.multi_rot = 0

local ComicBurst = require("word_game.ui.comic_burst")
local BURST_HOLD = 0.42
local BURST_FADE = 0.18
local POINTS_TO_GET_RAISE = 0.35
local pulse = 0

local function clamp01(t)
	if t < 0 then return 0 end
	if t > 1 then return 1 end
	return t
end

function M.pulse_togo()
	pulse = 1
end

function M.pulse_value()
	return pulse
end

function M.decay_pulse(dt)
	if pulse > 0 then
		pulse = math.max(0, pulse - dt * 2.4)
	end
end

function M.trigger_points_bounce(amp)
	M.points_bounce = { t = 0, dur = M.BOUNCE_DUR, amp = amp or 1.0 }
end

function M.trigger_multi_bounce(amp)
	M.multi_bounce = { t = 0, dur = M.BOUNCE_DUR, amp = amp or 1.0 }
end

function M.trigger_points_spin()
	local start_box = M.points_rot or 0
	local rot_delta = 4 * math.pi + math.pi / 4
	M.points_spin = {
		t = 0,
		dur = M.SPIN_DUR,
		start_box = start_box,
		target_box = start_box + rot_delta,
		rot_delta = rot_delta,
		digit_spin = 4 * math.pi,
	}
	M.spawn_points_burst()
end

function M.trigger_multi_spin()
	local start_box = M.multi_rot or 0
	local rot_delta = -(4 * math.pi + math.pi / 4)
	M.multi_spin = {
		t = 0,
		dur = M.SPIN_DUR,
		start_box = start_box,
		target_box = start_box + rot_delta,
		rot_delta = rot_delta,
		digit_spin = -(4 * math.pi),
	}
	M.spawn_multi_burst()
end

function M.spawn_points_burst()
	M.points_burst = ComicBurst.make(1)
end

function M.spawn_multi_burst()
	M.multi_burst = ComicBurst.make(1)
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
	ts = ts or ((G and G.TILESCALE or 1) * (G and G.TILESIZE or 1))
	local area = G and G.placement_table and G.placement_table.area
	local felt = Layout.felt_rect()
	local card_bottom = (area and area.T and area.T.y and area.T.h)
		and ((area.T.y + area.T.h) * ts)
		or ((felt.y + 2.0) * ts)
	local hand_top = (G and G.hand and G.hand.T and G.hand.T.y)
		and (G.hand.T.y * ts)
		or ((felt.y + felt.h - 2.5) * ts)
	local gap_cy = (card_bottom + hand_top) * 0.5 - ts * POINTS_TO_GET_RAISE
	return cx or ((felt.x + felt.w * 0.5) * ts), gap_cy
end

function M.hide_points_to_get_display()
	M.hide_points_to_get = true
	M.to_get_roll = nil
end

function M.reset_jumble_score()
	M.jumble_points = 0
	M.jumble_multi = 1.0
	M.hide_points_to_get = false
	M.points_roll = nil
	M.multi_roll = nil
	M.points_bounce = nil
	M.multi_bounce = nil
	M.points_spin = nil
	M.multi_spin = nil
	M.points_rot = 0
	M.multi_rot = 0
	M.points_burst = nil
	M.multi_burst = nil
	local target = (G.GAME and G.GAME.word_round and G.GAME.word_round.target) or 20
	local total = (G.GAME and G.GAME.word_round and G.GAME.word_round.jumble and G.GAME.word_round.jumble.total_score) or 0
	M.points_to_get = math.max(0, target - total)
	M.to_get_roll = nil
end

function M.roll_points_to_get(from_val, to_val, dur)
	from_val = from_val or M.points_to_get or 20
	to_val = to_val or from_val
	dur = dur or M.TO_GET_ROLL_TIME

	if from_val ~= to_val then
		M.to_get_roll = {
			from = from_val,
			to = to_val,
			t = 0,
			dur = dur,
			last_val = from_val,
		}
	else
		M.points_to_get = to_val
		M.to_get_roll = nil
	end
end

function M.roll_jumble_score(from_pts, to_pts, from_multi, to_multi)
	from_pts = from_pts or M.jumble_points or 0
	to_pts = to_pts or from_pts
	from_multi = from_multi or M.jumble_multi or 1.0
	to_multi = to_multi or from_multi

	local changed = false

	if from_pts ~= to_pts then
		M.points_roll = { from = from_pts, to = to_pts, t = 0, dur = M.ROLL_TIME }
		M.trigger_points_bounce(1.0)
		M.trigger_points_spin()
		changed = true
	else
		M.jumble_points = to_pts
		M.points_roll = nil
	end

	if math.abs(from_multi - to_multi) > 0.001 then
		M.multi_roll = { from = from_multi, to = to_multi, t = 0, dur = M.ROLL_TIME }
		M.trigger_multi_bounce(1.0)
		M.trigger_multi_spin()
		changed = true
	else
		M.jumble_multi = to_multi
		M.multi_roll = nil
	end

	if changed then
		M.pulse_togo()
		if play_sfx then play_sfx("card_tick", 0.75, 0.5) end
	end
end

function M.update(dt)
	dt = dt or (love and love.timer and love.timer.getDelta and math.min(0.05, love.timer.getDelta()) or 0.016)
	if M.points_roll then
		M.points_roll.t = M.points_roll.t + dt
		if M.points_roll.t >= M.points_roll.dur then
			M.jumble_points = M.points_roll.to
			M.points_roll = nil
		end
	end
	if M.multi_roll then
		M.multi_roll.t = M.multi_roll.t + dt
		if M.multi_roll.t >= M.multi_roll.dur then
			M.jumble_multi = M.multi_roll.to
			M.multi_roll = nil
		end
	end
	if M.points_bounce then
		M.points_bounce.t = M.points_bounce.t + dt
		if M.points_bounce.t >= M.points_bounce.dur then
			M.points_bounce = nil
		end
	end
	if M.multi_bounce then
		M.multi_bounce.t = M.multi_bounce.t + dt
		if M.multi_bounce.t >= M.multi_bounce.dur then
			M.multi_bounce = nil
		end
	end
	if M.points_spin then
		M.points_spin.t = M.points_spin.t + dt
		if M.points_spin.t >= M.points_spin.dur then
			M.points_rot = M.points_spin.target_box
			M.points_spin = nil
		end
	end
	if M.multi_spin then
		M.multi_spin.t = M.multi_spin.t + dt
		if M.multi_spin.t >= M.multi_spin.dur then
			M.multi_rot = M.multi_spin.target_box
			M.multi_spin = nil
		end
	end
	if M.points_burst then
		ComicBurst.advance(M.points_burst, dt)
		if M.points_burst.age > BURST_HOLD then
			M.points_burst.alpha = math.max(0, 1 - (M.points_burst.age - BURST_HOLD) / BURST_FADE)
		end
		if M.points_burst.alpha <= 0 then
			M.points_burst = nil
		end
	end
	if M.multi_burst then
		ComicBurst.advance(M.multi_burst, dt)
		if M.multi_burst.age > BURST_HOLD then
			M.multi_burst.alpha = math.max(0, 1 - (M.multi_burst.age - BURST_HOLD) / BURST_FADE)
		end
		if M.multi_burst.alpha <= 0 then
			M.multi_burst = nil
		end
	end
	if M.to_get_roll then
		M.to_get_roll.t = M.to_get_roll.t + dt
		local progress = math.min(1, M.to_get_roll.t / M.to_get_roll.dur)
		local cur = math.floor(M.to_get_roll.from - progress * (M.to_get_roll.from - M.to_get_roll.to) + 0.5)
		if cur ~= M.to_get_roll.last_val then
			M.to_get_roll.last_val = cur
			if play_sfx then play_sfx("card_tick", 0.7, 0.4) end
		end
		M.points_to_get = cur
		if M.to_get_roll.t >= M.to_get_roll.dur then
			M.points_to_get = M.to_get_roll.to
			M.to_get_roll = nil
		end
	end
end

return M
