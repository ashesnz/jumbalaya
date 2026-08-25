return function(AnimNode)
--- Critically-damped XY integration of VT toward T with a speed clamp.
function AnimNode:move_xy(dt)
	if (self.T.x ~= self.VT.x or math.abs(self.velocity.x) > 0.01) or
		(self.T.y ~= self.VT.y or math.abs(self.velocity.y) > 0.01) then
		self.velocity.x = G.smoothing.xy * self.velocity.x + (1 - G.smoothing.xy) * (self.T.x - self.VT.x) * 30 * dt
		self.velocity.y = G.smoothing.xy * self.velocity.y + (1 - G.smoothing.xy) * (self.T.y - self.VT.y) * 30 * dt
		local vel_sq = self.velocity.x^2 + self.velocity.y^2
		if vel_sq > G.smoothing.max_vel^2 then
			local actual_vel = math.sqrt(vel_sq)
			self.velocity.x = G.smoothing.max_vel * self.velocity.x / actual_vel
			self.velocity.y = G.smoothing.max_vel * self.velocity.y / actual_vel
		end
		self.STATIONARY = false
		self.VT.x = self.VT.x + self.velocity.x
		self.VT.y = self.VT.y + self.velocity.y
		if math.abs(self.VT.x - self.T.x) < 0.01 and math.abs(self.velocity.x) < 0.01 then
			self.VT.x = self.T.x; self.velocity.x = 0
		end
		if math.abs(self.VT.y - self.T.y) < 0.01 and math.abs(self.velocity.y) < 0.01 then
			self.VT.y = self.T.y; self.velocity.y = 0
		end
	end
end

--- Eases VT.scale toward T.scale plus zoom (drag/hover) and bounce offsets.
function AnimNode:move_scale(dt)
	local desired_scale = self.T.scale
		+ (self.zoom and ((self.states.drag.is and 0.08 or 0) + (self.states.hover.is and 0.04 or 0)) or 0)
		+ (self.bounce and self.bounce.scale or 0)

	if desired_scale ~= self.VT.scale or math.abs(self.velocity.scale) > 0.001 then
		self.STATIONARY = false
		self.velocity.scale = G.smoothing.scale * self.velocity.scale
			+ (1 - G.smoothing.scale) * (desired_scale - self.VT.scale)
		self.VT.scale = self.VT.scale + self.velocity.scale
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

--- Eases rotation; horizontal velocity feeds a subtle lean proportional to speed.
function AnimNode:move_r(dt, vel)
	local desired_r = self.T.r + 0.015 * vel.x / dt + (self.bounce and self.bounce.r * 2 or 0)

	if desired_r ~= self.VT.r or math.abs(self.velocity.r) > 0.001 then
		self.STATIONARY = false
		self.velocity.r = G.smoothing.r * self.velocity.r + (1 - G.smoothing.r) * (desired_r - self.VT.r)
		self.VT.r = self.VT.r + self.velocity.r
	end
	if math.abs(self.VT.r - self.T.r) < 0.001 and math.abs(self.velocity.r) < 0.001 then
		self.VT.r = self.T.r; self.velocity.r = 0
	end
end
end
