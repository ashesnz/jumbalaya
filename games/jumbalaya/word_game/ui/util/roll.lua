--[[
	word_game/ui/lib/roll.lua - Odometer roll state and easing.

	Shared by stage labels, sidebar counters, deck token display, and score
	banner points-to-get rolls.
]]

local M = {}

M.DEFAULT_TIME = 0.38

function M.clamp01(t)
	if t < 0 then return 0 end
	if t > 1 then return 1 end
	return t
end

function M.ease_out(t)
	t = M.clamp01(t)
	local inv = 1 - t
	return 1 - inv * inv * inv
end

--- Start a roll from `from` to `to`. Returns roll state and interim display value.
--- Pass `integer = true` to track stepped integer ticks (score banner).
function M.begin(from, to, dur, opts)
	opts = opts or {}
	dur = dur or M.DEFAULT_TIME
	if from == to then
		return nil, to
	end
	local roll = { from = from, to = to, t = 0, dur = dur }
	if opts.integer then
		roll.last_val = from
	end
	return roll, from
end

--- Advance a roll by dt. Returns updated roll (nil when done) and final value.
function M.tick(roll, dt)
	if not roll then return nil, nil end
	roll.t = roll.t + dt
	if roll.t >= roll.dur then
		return nil, roll.to
	end
	return roll, nil
end

--- View parameters for drawing a scrolling digit: from, to, eased progress, is_rolling.
function M.view(roll, fallback)
	if not roll then
		return fallback, fallback, 1, false
	end
	return roll.from, roll.to, M.ease_out(roll.t / roll.dur), true
end

--- Advance an integer-stepped roll; returns roll (nil when done), current value.
function M.tick_integer(roll, dt, on_tick)
	if not roll then return nil, nil end
	roll.t = roll.t + dt
	local progress = math.min(1, roll.t / roll.dur)
	local from, to = roll.from, roll.to
	local cur
	if to >= from then
		cur = math.floor(from + progress * (to - from) + 0.5)
	else
		cur = math.floor(from - progress * (from - to) + 0.5)
	end
	if cur ~= roll.last_val then
		roll.last_val = cur
		if on_tick then on_tick() end
	end
	if roll.t >= roll.dur then
		return nil, roll.to
	end
	return roll, cur
end

--- Mid-roll display value: `from` until eased progress passes 0.5, then `to`.
function M.halfway(roll)
	if not roll then return nil end
	if M.ease_out(roll.t / roll.dur) >= 0.5 then
		return roll.to
	end
	return roll.from
end

return M
