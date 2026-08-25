return function(ParticleEmitter)
local Scheduler = require("app.effects.scheduler")
--- Spawn pass: catch up on missed spawns (max 20 per frame to bound spikes).
function ParticleEmitter:update(dt)
	if G.SETTINGS.paused and not self.created_on_pause then
		self.last_real_time = G.TIMERS[self.timer_type]
		return
	end

	local added_this_frame = 0
	while G.TIMERS[self.timer_type] > self.last_real_time + self.timer
		and (#self.particles < self.max or self.pulsed < self.pulse_max)
		and added_this_frame < 20 do
		self.last_real_time = self.last_real_time + self.timer

		local offset = {
			x = self.fill and (0.5 - math.random()) * self.T.w or 0,
			y = self.fill and (0.5 - math.random()) * self.T.h or 0,
		}
		-- Rotate fill offsets with the emitter when it's only slightly tilted.
		if self.fill and self.T.r < 0.1 and self.T.r > -0.1 then
			offset = {
				x = math.sin(self.T.r) * offset.y + math.cos(self.T.r) * offset.x,
				y = math.sin(self.T.r) * offset.x + math.cos(self.T.r) * offset.y,
			}
		end

		table.insert(self.particles, {
			draw = false,
			dir = math.random() * 2 * math.pi,
			facing = math.random() * 2 * math.pi,
			size = math.random() * 0.5 + 0.1,
			age = 0,
			velocity = self.speed * (self.vel_variation * math.random() + (1 - self.vel_variation)) * 0.7,
			r_vel = 0.2 * (0.5 - math.random()),
			e_prev = 0,
			e_curr = 0,
			scale = 0,
			visible_scale = 0,
			time = G.TIMERS[self.timer_type],
			colour = pick_random(self.colours),
			offset = offset,
		})

		added_this_frame = added_this_frame + 1
		if self.pulsed <= self.pulse_max then self.pulsed = self.pulsed + 1 end
	end
end

--- Integrate every live particle through its size envelope and motion;
--- particles whose scale crosses below zero have finished their life.
function ParticleEmitter:move(dt)
	if G.SETTINGS.paused and not self.created_on_pause then return end

	AnimNode.move(self, dt)

	if self.timer_type ~= 'REAL' then dt = dt * G.TIME_SCALE end

	for i = #self.particles, 1, -1 do
		local p = self.particles[i]
		p.draw = true
		p.e_vel = p.e_vel or dt * self.scale
		p.e_prev = p.e_curr
		p.age = p.age + dt

		-- Envelope: grows over the first half of life, shrinks over the second.
		p.e_curr = math.min(
			2 * math.min((p.age / self.lifespan) * self.scale, self.scale * ((self.lifespan - p.age) / self.lifespan)),
			self.scale)

		p.e_vel = (p.e_curr - p.e_prev) * self.scale * dt + (1 - self.scale * dt) * p.e_vel
		p.scale = p.scale + p.e_vel
		p.scale = math.min(
			2 * math.min((p.age / self.lifespan) * self.scale, self.scale * ((self.lifespan - p.age) / self.lifespan)),
			self.scale)

		if p.scale < 0 then
			table.remove(self.particles, i)
		else
			p.offset.x = p.offset.x + p.velocity * math.sin(p.dir) * dt
			p.offset.y = p.offset.y + p.velocity * math.cos(p.dir) * dt
			p.facing = p.facing + p.r_vel * dt
			p.velocity = math.max(0, p.velocity - p.velocity * 0.07 * dt) -- drag
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
