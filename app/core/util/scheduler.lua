--[[
	app/core/util/scheduler.lua - the timeline: lanes of scheduled tweens.

	The Scheduler owns named lanes, each an ordered list of Tweens. Lanes tick
	on a fixed cadence; a blocking tween halts its lane until it finishes,
	unless later tweens opt out via blockable = false.
]]

return function(Scheduler)

function Scheduler:construct()
	self.lanes = {
		base = {},
		rewards = {},
		guide = {},
		badges = {},
		misc = {},
	}
	self.cadence_clock = G.TIMERS.REAL
	self.cadence_step = 1 / 60
	self.last_tick_at = G.TIMERS.REAL
end

--- Files a Tween onto a lane ('base' by default); non-Tweens are dropped.
--  `urgent` inserts at the head of the lane instead of appending.
function Scheduler:enqueue(tween, lane, urgent)
	lane = lane or 'base'
	if not tween:is_kind(Tween) then return end
	if urgent then
		table.insert(self.lanes[lane], 1, tween)
	else
		table.insert(self.lanes[lane], tween)
	end
end

-- In-place sweep that preserves persistent tweens.
local function sweep_lane(lane)
	local i = 1
	while i <= #lane do
		if not lane[i].persistent then
			table.remove(lane, i)
		else
			i = i + 1
		end
	end
end

--- Clears tweens off the lanes. Called with no arguments sweeps every lane;
--- with `(lane)` just that one; with `(lane, except)` all but the named one.
--- Persistent tweens always survive.
function Scheduler:flush(lane, except)
	if not lane then
		for _, l in pairs(self.lanes) do sweep_lane(l) end
	elseif except then
		for name, l in pairs(self.lanes) do
			if name ~= except then sweep_lane(l) end
		end
	else
		sweep_lane(self.lanes[lane])
	end
end

--- Runs all lanes when the fixed-step cadence elapses (or immediately on a
--- forced pass). Within a lane, a blocking tween stops later tweens from
--- ticking until it completes - unless they set blockable = false and pierce
--- the block. Finished tweens are retired.
function Scheduler:advance(dt, forced)
	self.cadence_clock = self.cadence_clock + dt
	if self.cadence_clock < self.last_tick_at + self.cadence_step and not forced then return end

	-- Forced passes don't advance the cadence cursor (they run "for free").
	self.last_tick_at = self.last_tick_at + (forced and 0 or self.cadence_step)

	for _, lane in pairs(self.lanes) do
		local blocked = false
		local i = 1
		while i <= #lane do
			G.ARGS.timeline_tick = G.ARGS.timeline_tick or {}
			local results = G.ARGS.timeline_tick
			results.blocking, results.completed, results.time_done, results.pause_skip = false, false, false, false

			if not blocked or not lane[i].blockable then lane[i]:tick(results) end

			if results.pause_skip then
				i = i + 1
			else
				if not blocked and results.blocking then blocked = true end
				if results.completed and results.time_done then
					table.remove(lane, i)
				else
					i = i + 1
				end
			end
		end
	end
end

end
