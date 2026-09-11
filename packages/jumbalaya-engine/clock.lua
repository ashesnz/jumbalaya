--[[
	jumbalaya-engine/clock.lua - Clock / timers service for testable time.
]]

---@class Clock
local Clock = {}
Clock.__index = Clock

function Clock.new(initial_time, opts)
	opts = opts or {}
	return setmetatable({
		_time = initial_time or 0,
		_time_fn = opts.time_fn,
	}, Clock)
end

function Clock.from_globals()
	return Clock.new(0, {
		time_fn = function()
			if _G.G and _G.G.TIMERS and _G.G.TIMERS.REAL then
				return _G.G.TIMERS.REAL
			end
			return 0
		end,
	})
end

function Clock:get_time()
	if self._time_fn then
		return self._time_fn()
	end
	return self._time
end

function Clock:advance(dt)
	if self._time_fn then
		if _G.G and _G.G.TIMERS then
			_G.G.TIMERS.REAL = (_G.G.TIMERS.REAL or 0) + (dt or 0)
			return _G.G.TIMERS.REAL
		end
		return self:get_time()
	end
	self._time = self._time + (dt or 0)
	return self._time
end

return Clock
