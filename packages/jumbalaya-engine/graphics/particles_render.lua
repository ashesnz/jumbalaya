return function(ParticleEmitter)
-- Geometry drawers. Each runs with the transform already translated to the
-- particle position and rotated to its angle; `s` is the current radius.
local SHAPE_DRAWERS = {
	orb = function(s)
		love.graphics.circle('fill', 0, 0, s * 0.5)
	end,
	ring = function(s)
		love.graphics.setLineWidth(math.max(s * 0.16, 0.5))
		love.graphics.circle('line', 0, 0, s * 0.55)
	end,
	shard = function(s)
		love.graphics.polygon('fill', 0, -s, s * 0.6, 0, 0, s, -s * 0.6, 0)
	end,
	tri = function(s)
		love.graphics.polygon('fill', 0, -s, s * 0.87, s * 0.5, -s * 0.87, s * 0.5)
	end,
}

function ParticleEmitter:draw(alpha)
	alpha = alpha or 1
	push_node_transform(self, 1)
	love.graphics.translate(self.T.w / 2, self.T.h / 2)

	for _, v in pairs(self.particles) do
		local drawer = SHAPE_DRAWERS[v.shape]
		if drawer then
			local s = v.size * v.env * self.scale * 2
			if s > 0.01 then
				local body_alpha = (v.colour[4] or 1) * alpha * (1 - self.fade_alpha) * (0.35 + 0.65 * v.env)
				if body_alpha > 0.003 then
					love.graphics.push()
					love.graphics.setColor(v.colour[1], v.colour[2], v.colour[3], body_alpha)
					love.graphics.translate(v.x, v.y)
					love.graphics.rotate(v.angle)
					drawer(s)
					love.graphics.pop()
				end
			end
		end
	end
	love.graphics.pop()

	track_hit_target(self)
	self:draw_boundingrect()
end

function ParticleEmitter:remove()
	-- Detach from the numeric child list of whatever we were attached to.
	if self.role.major then
		for k, v in pairs(self.role.major.children) do
			if v == self and type(k) == 'number' then
				table.remove(self.role.major.children, k)
			end
		end
	end

	teardown_tree(self.children)
	AnimNode.remove(self)
end
end
