
local BridgeRuntime = require("bridge.runtime")
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
			local shell = BridgeRuntime.game()
			if shell and shell.TIMERS and shell.TIMERS.REAL then
				return shell.TIMERS.REAL
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
		local shell = BridgeRuntime.game()
		if shell and shell.TIMERS then
			shell.TIMERS.REAL = (shell.TIMERS.REAL or 0) + (dt or 0)
			return shell.TIMERS.REAL
		end
		return self:get_time()
	end
	self._time = self._time + (dt or 0)
	return self._time
end

return Clock
