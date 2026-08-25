return function(ParticleEmitter)
function ParticleEmitter:draw(alpha)
	alpha = alpha or 1
	push_node_transform(self, 1)
	love.graphics.translate(self.T.w / 2, self.T.h / 2)

	for _, v in pairs(self.particles) do
		if v.draw then
			love.graphics.push()
			love.graphics.setColor(v.colour[1], v.colour[2], v.colour[3], v.colour[4] * alpha * (1 - self.fade_alpha))
			love.graphics.translate(v.offset.x, v.offset.y)
			love.graphics.rotate(v.facing)
			love.graphics.rectangle('fill', -v.scale / 2, -v.scale / 2, v.scale, v.scale)
			love.graphics.pop()
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
