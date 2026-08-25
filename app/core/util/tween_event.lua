--[[
	app/core/util/tween_event.lua - one entry on the timeline (Tween).

	A Tween is a unit of scheduled work owned by the Scheduler. Each carries a
	`mode` describing how it resolves:

		instant  - run once, finish immediately
		delayed  - wait out `delay`, then run once
		window   - tick every frame while waiting out `delay`
		watch    - tick until its predicate holds
		tween    - interpolate a value across `delay` using a shape curve

	Ticks report progress through a shared results record
	{blocking, completed, time_done, pause_skip} consumed by the Scheduler.
]]

return function(Tween)

function Tween:construct(config)
	self.mode = config.mode or 'instant'
	-- Boolean-safe defaults: `x ~= nil and x or true` would coerce an explicit
	-- `false` to `true`, so branch instead.
	self.blocking = true
	if config.blocking ~= nil then self.blocking = config.blocking end
	self.blockable = true
	if config.blockable ~= nil then self.blockable = config.blockable end

	self.finished = false
	self.clock_armed = config.start_timer or false -- true once the delay origin is captured
	self.armed_at = nil
	self.func = config.func or function() return true end
	self.delay = config.delay or 0
	self.persistent = config.persistent
	-- Tweens born mid-pause must ride the wall clock to make progress.
	self.born_paused = config.pause_force or G.SETTINGS.paused
	self.timer = config.timer or (self.born_paused and 'REAL') or 'TOTAL'

	if self.mode == 'tween' then
		self.motion = {
			shape = config.shape or 'linear',
			on = config.ref_table,
			key = config.ref_value,
			to = config.ease_to,
			from = nil,
			started_at = nil,
			ends_at = nil,
		}
		-- Transform funcs post-process the interpolated value (e.g. math.floor).
		self.func = config.func or function(t) return t end
	end

	if self.mode == 'watch' then
		local subject, key, goal = config.ref_table, config.ref_value, config.stop_val
		self.func = config.func or function() return subject[key] == goal end
	end
end

-- Wall-clock selector: tweens pick REAL time when they must move during pause.
local function clock(tween)
	return G.TIMERS[tween.timer]
end

------------------------------------------------------------------------
-- Mode tickers
------------------------------------------------------------------------

local MODE_TICKS = {}

MODE_TICKS.instant = function(tween, results)
	results.completed = tween.func()
	results.time_done = true
end

MODE_TICKS.delayed = function(tween, results)
	if tween.armed_at + tween.delay <= clock(tween) then
		results.time_done = true
		results.completed = tween.func()
	end
end

MODE_TICKS.window = function(tween, results)
	if not tween.finished then results.completed = tween.func() end
	if tween.armed_at + tween.delay <= clock(tween) then
		results.time_done = true
	end
end

MODE_TICKS.watch = function(tween, results)
	if not tween.finished then results.completed = tween.func() end
	results.time_done = true -- removal gated purely on completion
end

-- Progress shapers for tweens: each maps raw progress p (running 1 -> 0
-- across the window) to its eased counterpart.
local SHAPES = {
	linear = function(p) return p end,
	quad = function(p) return p * p end,
	elastic = function(p)
		return -math.pow(2, 10 * p - 10) * math.sin((p * 10 - 10.75) * 2 * math.pi / 2.6)
	end,
}

MODE_TICKS.tween = function(tween, results)
	local m = tween.motion
	if not m.started_at then
		m.started_at = clock(tween)
		m.ends_at = clock(tween) + tween.delay
		m.from = m.on[m.key]
	end

	if tween.finished then return end

	if m.ends_at >= clock(tween) then
		local p = (m.ends_at - clock(tween)) / (m.ends_at - m.started_at)
		p = SHAPES[m.shape](p)
		m.on[m.key] = tween.func(p * m.from + (1 - p) * m.to)
	else
		-- Window over: land exactly on the target value.
		m.on[m.key] = tween.func(m.to)
		tween.finished = true
		results.completed = true
		results.time_done = true
	end
end

--- Advances this tween one tick, filling the shared `results` record for the
--- Scheduler: {blocking, completed, time_done, pause_skip}.
function Tween:tick(results)
	results.blocking, results.completed = self.blocking, self.finished

	-- Frozen mid-pause (unless the tween itself was born during pause).
	if self.born_paused == false and G.SETTINGS.paused then
		results.pause_skip = true
		return
	end

	-- Capture the delay origin on our first processed tick.
	if not self.clock_armed then
		self.armed_at = clock(self)
		self.clock_armed = true
	end

	MODE_TICKS[self.mode](self, results)

	if results.completed then self.finished = true end
end

end
