return function(ParticleEmitter)
-- Shape palette available to emitters. Each particle picks one at birth;
-- render draws discs, diamonds, triangles, or rings accordingly.
ParticleEmitter.SHAPE_SETS = {
	soft = { 'orb', 'shard' },
	sharp = { 'shard', 'tri' },
	rings = { 'orb', 'ring' },
}

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

	-- Emission model: a credit budget refilled at `rate` credits/second.
	-- One credit buys one particle. Debt after hitches is capped so the
	-- emitter never dumps a wall of particles on resume.
	self.timer = config.timer or 0.5            -- seconds between particles
	self.rate = self.timer > 0 and 1 / self.timer or 20
	self.emit_credit = 1                        -- start ready to fire once
	self.max_debt = 20                          -- never owe more than this many
	self.burst_allowance = math.min(20, config.pulse_max or 0)
	self.spawned_this_frame_cap = 24

	self.timer_type = (self.created_on_pause and 'REAL') or config.timer_type or 'REAL'
	self.last_tick = G.TIMERS[self.timer_type]
	self.lifespan = config.lifespan or 1
	self.fade_alpha = 0
	self.speed = config.speed or 1
	self.max = config.max or 1000000000000000

	-- Motion character: speed jitter and a mild per-particle swirl make
	-- streams look organic rather than radial-symmetric.
	self.vel_variation = config.vel_variation or 1
	self.swirl = config.swirl or 0.6
	self.shapes = config.shapes or ParticleEmitter.SHAPE_SETS.soft

	self.particles = {}
	self.scale = config.scale or 1
	self.colours = config.colours or {G.C.BACKGROUND.D}

	-- Prewarm: rewind the clock and simulate history so the field starts full.
	if config.initialize then
		local step = 15 / 60
		for _ = 1, 60 do
			self.last_tick = self.last_tick - step
			self:update(step)
			self:move(step)
		end
	end

	if getmetatable(self) == Particles then table.insert(G.LIVE.TRANSFORM, self) end
end
end
