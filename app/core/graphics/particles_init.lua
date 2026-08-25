return function(ParticleEmitter)
function ParticleEmitter:construct(X, Y, W, H, config)
	config = config or {}

	AnimNode.construct(self, X, Y, W, H)

	self.fill = config.fill -- spread spawn points across our rect instead of the center
	self.padding = config.padding or 0

	if config.attach then
		self:set_alignment{
			major = config.attach,
			type = 'cm',
			bond = 'Strong',
		}
		table.insert(self.role.major.children, self)
		self.parent = self.role.major
		self.T.x = self.role.major.T.x + self.padding
		self.T.y = self.role.major.T.y + self.padding
		if self.fill then
			self.T.w = self.role.major.T.w - self.padding
			self.T.h = self.role.major.T.h - self.padding
		end
	end

	-- Emitters are purely visual; never interact with the cursor.
	self.states.hover.can = false
	self.states.click.can = false
	self.states.collide.can = false
	self.states.drag.can = false
	self.states.release_on.can = false

	self.timer = config.timer or 0.5
	self.timer_type = (self.created_on_pause and 'REAL') or config.timer_type or 'REAL'
	self.last_real_time = G.TIMERS[self.timer_type] - self.timer
	self.last_drawn = 0
	self.lifespan = config.lifespan or 1
	self.fade_alpha = 0
	self.speed = config.speed or 1
	self.max = config.max or 1000000000000000
	self.pulse_max = math.min(20, config.pulse_max or 0) -- extra allowance for bursts
	self.pulsed = 0
	self.vel_variation = config.vel_variation or 1
	self.particles = {}
	self.scale = config.scale or 1
	self.colours = config.colours or {G.C.BACKGROUND.D}

	-- Prewarm: simulate a second of history so the field starts populated.
	if config.initialize then
		for _ = 1, 60 do
			self.last_real_time = self.last_real_time - 15 / 60
			self:update(15 / 60)
			self:move(15 / 60)
		end
	end

	if getmetatable(self) == Particles then table.insert(G.LIVE.TRANSFORM, self) end
end
end
