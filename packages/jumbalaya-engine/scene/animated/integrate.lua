
-- Semi-implicit Euler springs: VT tracks T. Stiffness/damping live here,
-- not as per-frame exp rates on the game shell.
local XY_OMEGA, XY_ZETA = 14.5, 0.82
local SCALE_OMEGA, SCALE_ZETA = 18, 0.76
local R_OMEGA, R_ZETA = 16.5, 0.88
local POS_SNAP, VEL_SNAP = 0.01, 0.012
local SCALE_SNAP, R_SNAP = 0.002, 0.001
local LEAN = 0.07
local LEAN_MAX = 0.11

local function spring_to(pos, vel, target, dt, omega, zeta)
	local acc = omega * omega * (target - pos) - 2 * zeta * omega * vel
	vel = vel + acc * dt
	pos = pos + vel * dt
	return pos, vel
end

return function(AnimNode)
--- Spring-integrates VT.xy toward T.xy.
function AnimNode:move_xy(dt)
	if dt <= 0 then return end
	if (self.T.x ~= self.VT.x or math.abs(self.velocity.x) > VEL_SNAP)
		or (self.T.y ~= self.VT.y or math.abs(self.velocity.y) > VEL_SNAP) then
		self.VT.x, self.velocity.x = spring_to(self.VT.x, self.velocity.x, self.T.x, dt, XY_OMEGA, XY_ZETA)
		self.VT.y, self.velocity.y = spring_to(self.VT.y, self.velocity.y, self.T.y, dt, XY_OMEGA, XY_ZETA)
		self.STATIONARY = false
		if math.abs(self.VT.x - self.T.x) < POS_SNAP and math.abs(self.velocity.x) < VEL_SNAP then
			self.VT.x = self.T.x
			self.velocity.x = 0
		end
		if math.abs(self.VT.y - self.T.y) < POS_SNAP and math.abs(self.velocity.y) < VEL_SNAP then
			self.VT.y = self.T.y
			self.velocity.y = 0
		end
	end
end

--- Springs VT.scale toward T.scale plus zoom (drag/hover) and bounce offsets.
function AnimNode:move_scale(dt)
	if dt <= 0 then return end
	local desired_scale = self.T.scale
		+ (self.zoom and ((self.states.drag.is and 0.08 or 0) + (self.states.hover.is and 0.04 or 0)) or 0)
		+ (self.bounce and self.bounce.scale or 0)

	if desired_scale ~= self.VT.scale or math.abs(self.velocity.scale) > SCALE_SNAP then
		self.STATIONARY = false
		self.VT.scale, self.velocity.scale = spring_to(self.VT.scale, self.velocity.scale, desired_scale, dt, SCALE_OMEGA, SCALE_ZETA)
		if math.abs(self.VT.scale - desired_scale) < SCALE_SNAP and math.abs(self.velocity.scale) < SCALE_SNAP then
			self.VT.scale = desired_scale
			self.velocity.scale = 0
		end
	end
end

--- Eases width/height toward T, collapsing toward 0 on pinched axes (flips).
function AnimNode:move_wh(dt)
	if (self.T.w ~= self.VT.w and not self.pinch.x) or
		(self.T.h ~= self.VT.h and not self.pinch.y) or
		(self.VT.w > 0 and self.pinch.x) or
		(self.VT.h > 0 and self.pinch.y) then
		self.STATIONARY = false
		self.VT.w = self.VT.w + 6.5 * dt * (self.pinch.x and -1 or 1) * self.T.w
		self.VT.h = self.VT.h + 6.5 * dt * (self.pinch.y and -1 or 1) * self.T.h
		self.VT.w = math.max(math.min(self.VT.w, self.T.w), 0)
		self.VT.h = math.max(math.min(self.VT.h, self.T.h), 0)
	end
end

--- Springs rotation; horizontal velocity adds a clamped lean.
function AnimNode:move_r(dt, vel)
	if dt <= 0 then return end
	local lean = vel.x * LEAN
	if lean > LEAN_MAX then lean = LEAN_MAX elseif lean < -LEAN_MAX then lean = -LEAN_MAX end
	local desired_r = self.T.r + lean + (self.bounce and self.bounce.r * 2 or 0)

	if desired_r ~= self.VT.r or math.abs(self.velocity.r) > R_SNAP then
		self.STATIONARY = false
		self.VT.r, self.velocity.r = spring_to(self.VT.r, self.velocity.r, desired_r, dt, R_OMEGA, R_ZETA)
	end
	if math.abs(self.VT.r - self.T.r) < R_SNAP and math.abs(self.velocity.r) < R_SNAP then
		self.VT.r = self.T.r
		self.velocity.r = 0
	end
end
end
