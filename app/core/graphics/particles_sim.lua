return function(ParticleEmitter)
local Scheduler = require("app.effects.scheduler")

--- Spawns one particle. Records carry velocity components, a per-particle
--- lifespan, and a geometry choice — deliberately unlike the old uniform
--- {dir, facing, size, age} record.
local function spawn(self)
	local heading = math.random() * 2 * math.pi
	local jitter = self.speed * (self.vel_variation * math.random() + (1 - self.vel_variation))
	local speed = self.speed * 0.7 + 0.3 * jitter
	local offset = {x = 0, y = 0}
	if self.fill then
		offset.x = (0.5 - math.random()) * self.T.w
		offset.y = (0.5 - math.random()) * self.T.h
		-- Rotate fill offsets with the emitter when it's only slightly tilted.
		if self.T.r < 0.1 and self.T.r > -0.1 then
			offset = {
				x = math.sin(self.T.r) * offset.y + math.cos(self.T.r) * offset.x,
				y = math.sin(self.T.r) * offset.x + math.cos(self.T.r) * offset.y,
			}
		end
	end

	self.particles[#self.particles + 1] = {
		x = offset.x,
		y = offset.y,
		vx = speed * math.cos(heading),
		vy = speed * math.sin(heading),
		angle = math.random() * 2 * math.pi,
		spin = 2.4 * (math.random() - 0.5),
		swirl = self.swirl * (math.random() < 0.5 and -1 or 1),
		size = 0.08 + 0.27 * math.random(),
		age = 0,
		life = self.lifespan * (0.75 + 0.5 * math.random()),
		colour = pick_random(self.colours),
		shape = pick_random(self.shapes),
		env = 0,
	}
end

--- Emission pass: refill the spawn-credit budget from elapsed time, then
--- spend credits. Bursts may exceed `max` while burst allowance remains.
function ParticleEmitter:update(dt)
	local now = G.TIMERS[self.timer_type]
	local elapsed = now - (self.last_tick or now)
	self.last_tick = now

	if G.SETTINGS.paused and not self.created_on_pause then return end

	self.emit_credit = math.min(self.emit_credit + elapsed * self.rate, self.max_debt)

	local spent = 0
	while self.emit_credit >= 1 and spent < self.spawned_this_frame_cap do
		if #self.particles >= self.max then
			if self.burst_allowance <= 0 then break end
			self.burst_allowance = self.burst_allowance - 1
		end
		spawn(self)
		self.emit_credit = self.emit_credit - 1
		spent = spent + 1
	end
end

--- Integration pass: sine-bell size envelope, damped drift with swirl.
--- A particle dies of old age (past its own `life`) instead of relying on a
--- scale sign flip.
function ParticleEmitter:move(dt)
	if G.SETTINGS.paused and not self.created_on_pause then return end

	AnimNode.move(self, dt)

	if self.timer_type ~= 'REAL' then dt = dt * G.TIME_SCALE end
	local damp = math.max(0, 1 - 1.4 * dt)

	for i = #self.particles, 1, -1 do
		local p = self.particles[i]
		p.age = p.age + dt

		if p.age >= p.life then
			table.remove(self.particles, i)
		else
			-- Smooth bell envelope over life; squared softening near death.
			local k = p.age / p.life
			p.env = math.sin(k * math.pi)

			-- Swirl: bend the heading over time for curling motion.
			local cos_s, sin_s = math.cos(p.swirl * dt), math.sin(p.swirl * dt)
			local vx = p.vx * cos_s - p.vy * sin_s
			local vy = p.vx * sin_s + p.vy * cos_s
			p.vx = vx * damp
			p.vy = vy * damp

			p.x = p.x + p.vx * dt
			p.y = p.y + p.vy * dt
			p.angle = p.angle + p.spin * dt
		end
	end
end

--- Eases system-wide transparency toward `to` (default 1) after `delay`.
function ParticleEmitter:fade(delay, to)
	Scheduler.add{
		mode = 'tween',
		timer = self.timer_type,
		blockable = false,
		blocking = false,
		ref_value = 'fade_alpha',
		ref_table = self,
		ease_to = to or 1,
		delay = delay,
	}
end
end
