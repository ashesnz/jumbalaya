--[[
	jumbalaya-engine/clock.lua - Clock / timers service for testable time.
]]

---@class Clock
local Clock = {}
Clock.__index = Clock

function Clock.new(initial_time)
	return setmetatable({ _time = initial_time or 0 }, Clock)
end

function Clock:get_time()
	return self._time
end

function Clock:advance(dt)
	self._time = self._time + (dt or 0)
	return self._time
end

return Clock
