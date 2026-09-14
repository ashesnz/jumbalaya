--[[ word_game/ui/score_banner/jumble/state.lua - Mutable jumble score banner state ]]

local M = {}

M.jumble_points = 0
M.jumble_multi = 1.0
M.points_earned = 0
M.points_got = 0
M.points_to_get = 20
M.hide_points_to_get = false
M.points_roll = nil
M.multi_roll = nil
M.to_get_roll = nil
M.got_roll = nil

M.points_burst = nil
M.multi_burst = nil
M.points_bounce = nil
M.multi_bounce = nil
M.points_spin = nil
M.multi_spin = nil
M.points_rot = 0
M.multi_rot = 0

local pulse = 0

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

function M.hide_points_to_get_display()
	M.hide_points_to_get = true
	M.to_get_roll = nil
	M.got_roll = nil
end

function M.format_score_equation()
	local earned = math.floor(M.points_earned or 0)
	local got = math.floor(M.points_got or 0)
	local remaining = math.floor(M.points_to_get or 0)
	return string.format("%d Earnt + %d = %d Remaining", earned, got, remaining)
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
	M.to_get_roll = nil
	M.got_roll = nil
end

return M
