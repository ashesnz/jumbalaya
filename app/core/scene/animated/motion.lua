return function(AnimNode)
local MWM
--- Per-frame entry point. Frame-gated so repeated calls in one frame are free;
--- Majors integrate their own VT, Minors follow their major, Glued copies it.
function AnimNode:move(dt)
	if self.FRAME.TRANSFORM >= G.FRAMES.TRANSFORM then return end
	self.FRAME.MAJOR = nil
	self.FRAME.TRANSFORM = G.FRAMES.TRANSFORM
	if not self.created_on_pause and G.SETTINGS.paused then return end

	self:align_to_major()

	self.CALCING = nil
	if self.role.role_type == 'Glued' then
		if self.role.major then self:glue_to_major(self.role.major) end
	elseif self.role.role_type == 'Minor' and self.role.major then
		if self.role.major.FRAME.TRANSFORM < G.FRAMES.TRANSFORM then self.role.major:move(dt) end
		self.STATIONARY = self.role.major.STATIONARY
		-- Weak bonds and transient effects force a full recompute even when
		-- the major reports itself stationary.
		if (not self.STATIONARY) or self.NEW_ALIGNMENT
			or self.config.refresh_movement
			or self.bounce
			or self.role.xy_bond == 'Weak'
			or self.role.r_bond == 'Weak' then
			self.CALCING = true
			self:move_with_major(dt)
		end
	elseif self.role.role_type == 'Major' then
		self.STATIONARY = true
		self:advance_bounce(dt)
		self:move_xy(dt)
		self:move_r(dt, self.velocity)
		self:move_scale(dt)
		self:move_wh(dt)
		self:calculate_parallax()
	end
	self.NEW_ALIGNMENT = false
end

--- Hard transform sharing for Glued minors (stacked cards).
function AnimNode:glue_to_major(major_tab)
	self.T = major_tab.T

	-- Keep the visible rect centered as the major's width animates.
	self.VT.x = major_tab.VT.x + (0.5 * (1 - major_tab.VT.w / major_tab.T.w) * self.T.w)
	self.VT.y = major_tab.VT.y
	self.VT.w = major_tab.VT.w
	self.VT.h = major_tab.VT.h
	self.VT.r = major_tab.VT.r
	self.VT.scale = major_tab.VT.scale

	self.pinch = major_tab.pinch
	self.shadow_parallax = major_tab.shadow_parallax
end

--- Minor follow pass: derives this frame's cumulative major offset (rotated
--- into the major's space when needed), then applies bonds.
function AnimNode:move_with_major(dt)
	if self.role.role_type ~= 'Minor' then return end
	local major_tab = self.role.major:get_major()

	self:advance_bounce(dt)

	MWM = MWM or {rotated_offset = {}, angles = {}, WH = {}, offs = {}}

	if self.role.r_bond == 'Weak' then
		-- Rotation handled by our own integrator; plain additive offset.
		MWM.rotated_offset.x = self.role.offset.x + major_tab.offset.x
		MWM.rotated_offset.y = self.role.offset.y + major_tab.offset.y
	elseif math.abs(major_tab.major.VT.r) < 0.0001 then
		MWM.rotated_offset.x = self.role.offset.x + major_tab.offset.x
		MWM.rotated_offset.y = self.role.offset.y + major_tab.offset.y
	else
		-- Rotate the combined offset around the size-difference midpoint.
		local cos_r, sin_r = math.cos(major_tab.major.VT.r), math.sin(major_tab.major.VT.r)
		local hw = -self.T.w / 2 + major_tab.major.T.w / 2
		local hh = -self.T.h / 2 + major_tab.major.T.h / 2
		local ox = self.role.offset.x + major_tab.offset.x - hw
		local oy = self.role.offset.y + major_tab.offset.y - hh
		MWM.rotated_offset.x = ox * cos_r - oy * sin_r + hw
		MWM.rotated_offset.y = ox * sin_r + oy * cos_r + hh
	end

	self.T.x = major_tab.major.T.x + MWM.rotated_offset.x
	self.T.y = major_tab.major.T.y + MWM.rotated_offset.y

	if self.role.xy_bond == 'Strong' then
		self.VT.x = major_tab.major.VT.x + MWM.rotated_offset.x
		self.VT.y = major_tab.major.VT.y + MWM.rotated_offset.y
	elseif self.role.xy_bond == 'Weak' then
		self:move_xy(dt)
	end

	if self.role.r_bond == 'Strong' then
		self.VT.r = self.T.r + major_tab.major.VT.r + (self.bounce and self.bounce.r or 0)
	elseif self.role.r_bond == 'Weak' then
		self:move_r(dt, self.velocity)
	end

	if self.role.scale_bond == 'Strong' then
		self.VT.scale = self.T.scale * (major_tab.major.VT.scale / major_tab.major.T.scale)
			+ (self.bounce and self.bounce.scale or 0)
	elseif self.role.scale_bond == 'Weak' then
		self:move_scale(dt)
	end

	if self.role.wh_bond == 'Strong' then
		self.VT.x = self.VT.x + (0.5 * (1 - major_tab.major.VT.w / major_tab.major.T.w) * self.T.w)
		self.VT.w = self.T.w * (major_tab.major.VT.w / major_tab.major.T.w)
		self.VT.h = self.T.h * (major_tab.major.VT.h / major_tab.major.T.h)
	elseif self.role.wh_bond == 'Weak' then
		self:move_wh(dt)
	end

	self:calculate_parallax()
end
end
