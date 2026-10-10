
local Random = require("jumbalaya-engine.util.random")

local PULSE_OMEGA = 21
local PULSE_ZETA = 0.28
local PULSE_R_OMEGA = 16
local PULSE_R_ZETA = 0.36
local SPEECH_OMEGA = 13
local SPEECH_ZETA = 0.33
local SETTLE = 0.003

local function spring_step(pos, vel, dt, omega, zeta)
	local acc = -omega * omega * pos - 2 * zeta * omega * vel
	vel = vel + acc * dt
	pos = pos + vel * dt
	return pos, vel
end

return function(Spatial)
--- One-shot squash: compress, then an underdamped spring overshoots and settles.
function Spatial:pulse(amount, rot_amt)
	amount = amount or 0.4
	local twist = rot_amt or Random.pick_random({ 0.55 * amount, -0.55 * amount }) or 0
	self.bounce = {
		scale = -0.62 * amount,
		scale_vel = 11 * amount,
		r = 0,
		r_vel = 12 * twist,
		omega = PULSE_OMEGA,
		zeta = PULSE_ZETA,
		r_omega = PULSE_R_OMEGA,
		r_zeta = PULSE_R_ZETA,
	}
	self.VT.scale = (self.T.scale or 1) + self.bounce.scale
end

--- Softer spring used for speech bubbles (distinct stiffness from pulse).
function Spatial:speech_pop()
	self.bounce = {
		scale = -0.2,
		scale_vel = 5.5,
		r = 0,
		r_vel = 1.1,
		omega = SPEECH_OMEGA,
		zeta = SPEECH_ZETA,
		r_omega = 10,
		r_zeta = 0.4,
	}
end

--- Integrates the bounce spring toward rest; clears it when settled.
function Spatial:advance_bounce(dt)
	local bounce = self.bounce
	if not bounce or bounce.handled_elsewhere then return end
	if not dt or dt <= 0 then return end

	local omega = bounce.omega or PULSE_OMEGA
	local zeta = bounce.zeta or PULSE_ZETA
	bounce.scale, bounce.scale_vel = spring_step(bounce.scale, bounce.scale_vel or 0, dt, omega, zeta)
	bounce.r, bounce.r_vel = spring_step(bounce.r, bounce.r_vel or 0, dt, bounce.r_omega or PULSE_R_OMEGA, bounce.r_zeta or PULSE_R_ZETA)

	local energy = math.abs(bounce.scale) + math.abs(bounce.r)
		+ math.abs(bounce.scale_vel) + math.abs(bounce.r_vel)
	if energy < SETTLE then
		self.bounce = nil
	end
end
end
