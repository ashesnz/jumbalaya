return function(AnimNode)
--- Quick squash-and-stretch pulse (the classic "card bounce").
function AnimNode:pulse(amount, rot_amt)
	amount = amount or 0.4
	local start_time = G.TIMERS.REAL
	self.bounce = {
		scale = 0,
		scale_amt = amount,
		r = 0,
		r_amt = ((rot_amt or pick_random({0.6 * amount, -0.6 * amount})) or 0),
		start_time = start_time,
		end_time = start_time + 0.4,
	}
	self.VT.scale = 1 - 0.5 * amount
end

--- Softer elastic settle used for speech bubbles (distinct from pulse).
function AnimNode:speech_pop()
	self.bounce = {
		kind = "speech",
		scale = -0.22,
		scale_amt = 0.22,
		r = 0,
		r_amt = 0.055,
		start_time = G.TIMERS.REAL,
		end_time = G.TIMERS.REAL + 0.52,
	}
end

--- Advances the active bounce envelope; clears it once past `end_time`.
function AnimNode:advance_bounce(dt)
	local bounce = self.bounce
	if not bounce or bounce.handled_elsewhere then return end

	if bounce.end_time < G.TIMERS.REAL then
		self.bounce = nil
		return
	end

	if bounce.kind == "speech" then
		local u = (G.TIMERS.REAL - bounce.start_time) / (bounce.end_time - bounce.start_time)
		if u >= 1 then
			self.bounce = nil
		else
			-- Elastic-out ring: single overshoot plus a soft second bump.
			local elastic = (2 ^ (-9.2 * u)) * math.sin((u * 9.4 - 0.75) * (2 * math.pi) / 3.1)
			bounce.scale = -0.04 + bounce.scale_amt * elastic
			bounce.r = bounce.r_amt * (2 ^ (-7.4 * u)) * math.sin(u * 6.4)
		end
	else
		local elapsed = G.TIMERS.REAL - bounce.start_time
		local remaining_frac = (bounce.end_time - G.TIMERS.REAL) / (bounce.end_time - bounce.start_time)
		bounce.scale = bounce.scale_amt * math.sin(44 * elapsed) * math.max(0, remaining_frac^2.5)
		bounce.r = bounce.r_amt * math.sin(36 * elapsed) * math.max(0, remaining_frac^1.5)
	end
end
end
