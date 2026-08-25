--[[
	app/effects/dissolve_fx.lua - generic dissolve / materialize effects.

	Drives a timed dissolve animation on any node exposing a numeric
	`dissolve` field (0 = intact, 1 = fully dissolved), pairing the shader
	uniform tween with attach-mounted particles and completion hooks.
	Knows nothing about Card — works for any Moveable-style node.
]]

local Scheduler = require "app.effects.scheduler"

local DissolveFX = {}

--- Runs a dissolve-style animation.
--- @param target any node with a `dissolve` field; optional `pulse`/`remove`
--- @param opts table options:
---   mode         'out' (default) dissolves away; 'in' materializes
---   duration     base duration in seconds (default 0.7)
---   colours      particle/shader tint colours (default white)
---   pulse        call target:pulse() at start
---   particle     {timer, scale, speed, lifespan} overrides
---   fade         {delay, duration} particle fade-out; `cap = true` stops
---                emission instantly instead of fading
---   tween_delay  delay before the dissolve uniform starts tweening
---   remove       remove the node when the animation completes
---   on_start     fn(target) fired immediately
---   on_finish    fn(target) fired just before removal
function DissolveFX.run(target, opts)
	opts = opts or {}
	local mode = opts.mode or 'out'
	local duration = opts.duration or 0.7
	local p = opts.particle or {}

	target.dissolve = (mode == 'in') and 1 or 0
	target.dissolve_colours = opts.colours or {G.C.WHITE}

	if opts.on_start then opts.on_start(target) end
	if opts.pulse and target.pulse then target:pulse() end

	local parts = Particles(0, 0, 0, 0, {
		timer_type = 'TOTAL',
		timer = (p.timer or (mode == 'in' and 0.025 or 0.01)) * duration,
		scale = p.scale or (mode == 'in' and 0.25 or 0.1),
		speed = p.speed or (mode == 'in' and 3 or 2),
		lifespan = (p.lifespan or 0.7) * duration,
		attach = target,
		colours = target.dissolve_colours,
		fill = true,
	})

	local fade = opts.fade or {}
	Scheduler.add{
		mode = 'delayed',
		blockable = false,
		delay = fade.delay or duration,
		func = function()
			if fade.cap then parts.max = 0 else parts:fade(fade.duration or 0.3 * duration) end
			return true
		end,
	}

	local tween_delay = opts.tween_delay or duration
	Scheduler.add{
		mode = 'tween',
		blockable = false,
		ref_table = target,
		ref_value = 'dissolve',
		ease_to = (mode == 'in') and 0 or 1,
		delay = tween_delay,
		func = function(t) return t end,
	}

	Scheduler.add{
		mode = 'delayed',
		blockable = false,
		delay = tween_delay + 0.05 * duration,
		func = function()
			if opts.on_finish then opts.on_finish(target) end
			if opts.remove then target:remove() end
			return true
		end,
	}

	return parts
end

return DissolveFX
