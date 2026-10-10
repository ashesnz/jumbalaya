
-- Semi-implicit Euler springs: drawn tracks target. Stiffness/damping live here,
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

local function unsettle(self)
	self.settled = false
end

return function(Spatial)
--- Spring-integrates drawn.xy toward target.xy.
function Spatial:move_xy(dt)
	if dt <= 0 then return end
	local T = self.target or self.T
	local VT = self.drawn or self.VT
	if (T.x ~= VT.x or math.abs(self.velocity.x) > VEL_SNAP)
		or (T.y ~= VT.y or math.abs(self.velocity.y) > VEL_SNAP) then
		VT.x, self.velocity.x = spring_to(VT.x, self.velocity.x, T.x, dt, XY_OMEGA, XY_ZETA)
		VT.y, self.velocity.y = spring_to(VT.y, self.velocity.y, T.y, dt, XY_OMEGA, XY_ZETA)
		unsettle(self)
		if math.abs(VT.x - T.x) < POS_SNAP and math.abs(self.velocity.x) < VEL_SNAP then
			VT.x = T.x
			self.velocity.x = 0
		end
		if math.abs(VT.y - T.y) < POS_SNAP and math.abs(self.velocity.y) < VEL_SNAP then
			VT.y = T.y
			self.velocity.y = 0
		end
	end
end

--- Springs drawn.scale toward target.scale plus zoom (drag/hover) and bounce offsets.
function Spatial:move_scale(dt)
	if dt <= 0 then return end
	local T = self.target or self.T
	local VT = self.drawn or self.VT
	local desired_scale = T.scale
		+ (self.zoom and ((self.states.dragging and 0.08 or 0) + (self.states.hovering and 0.04 or 0)) or 0)
		+ (self.bounce and self.bounce.scale or 0)

	if desired_scale ~= VT.scale or math.abs(self.velocity.scale) > SCALE_SNAP then
		unsettle(self)
		VT.scale, self.velocity.scale = spring_to(VT.scale, self.velocity.scale, desired_scale, dt, SCALE_OMEGA, SCALE_ZETA)
		if math.abs(VT.scale - desired_scale) < SCALE_SNAP and math.abs(self.velocity.scale) < SCALE_SNAP then
			VT.scale = desired_scale
			self.velocity.scale = 0
		end
	end
end

--- Eases width/height toward target, collapsing toward 0 on pinched axes (flips).
function Spatial:move_wh(dt)
	local T = self.target or self.T
	local VT = self.drawn or self.VT
	if (T.w ~= VT.w and not self.pinch.x) or
		(T.h ~= VT.h and not self.pinch.y) or
		(VT.w > 0 and self.pinch.x) or
		(VT.h > 0 and self.pinch.y) then
		unsettle(self)
		VT.w = VT.w + 6.5 * dt * (self.pinch.x and -1 or 1) * T.w
		VT.h = VT.h + 6.5 * dt * (self.pinch.y and -1 or 1) * T.h
		VT.w = math.max(math.min(VT.w, T.w), 0)
		VT.h = math.max(math.min(VT.h, T.h), 0)
	end
end

--- Springs rotation; horizontal velocity adds a clamped lean.
function Spatial:move_r(dt, vel)
	if dt <= 0 then return end
	local T = self.target or self.T
	local VT = self.drawn or self.VT
	local lean = vel.x * LEAN
	if lean > LEAN_MAX then lean = LEAN_MAX elseif lean < -LEAN_MAX then lean = -LEAN_MAX end
	local desired_r = T.r + lean + (self.bounce and self.bounce.r * 2 or 0)

	if desired_r ~= VT.r or math.abs(self.velocity.r) > R_SNAP then
		unsettle(self)
		VT.r, self.velocity.r = spring_to(VT.r, self.velocity.r, desired_r, dt, R_OMEGA, R_ZETA)
	end
	if math.abs(VT.r - T.r) < R_SNAP and math.abs(self.velocity.r) < R_SNAP then
		VT.r = T.r
		self.velocity.r = 0
	end
end
end
