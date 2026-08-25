--[[
	app/effects/scheduler.lua - local tween scheduling for runtime effects.

	Thin conveniences over the global timeline: each helper stamps the tween
	mode, hands the options table to Tween(), and files it on G.TIMELINE.
]]

local Scheduler = {}

function Scheduler.add(options)
	local tween = Tween(options.event or options)
	G.TIMELINE:enqueue(tween, options.lane, options.urgent)
	return tween
end

function Scheduler.delayed(options)
	options.mode = 'delayed'
	return Scheduler.add(options)
end

function Scheduler.window(options)
	options.mode = 'window'
	return Scheduler.add(options)
end

function Scheduler.instant(options)
	options.mode = 'instant'
	return Scheduler.add(options)
end

function Scheduler.tween(options)
	options.mode = 'tween'
	return Scheduler.add(options)
end

Scheduler.schedule = Scheduler.add

return Scheduler
