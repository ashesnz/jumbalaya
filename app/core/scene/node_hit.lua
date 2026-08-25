return function(Node)
	function Node:collides_with_point(point)
		if not self.container then return end

		local T = self.CT or self.T
		self.ARGS.collides_with_point_point = self.ARGS.collides_with_point_point or {}
		self.ARGS.collides_with_point_translation = self.ARGS.collides_with_point_translation or {}
		self.ARGS.collides_with_point_rotation = self.ARGS.collides_with_point_rotation or {}
		local p = self.ARGS.collides_with_point_point
		local t = self.ARGS.collides_with_point_translation
		local rot = self.ARGS.collides_with_point_rotation

		local buffer = self.states.hover.is and G.COLLISION_BUFFER or 0
		p.x, p.y = point.x, point.y

		if self.container ~= self then
			if math.abs(self.container.T.r) < 0.1 then
				t.x, t.y = -self.container.T.w / 2, -self.container.T.h / 2
				shift_point(p, t)
				rotate_point(p, self.container.T.r)
				t.x, t.y = self.container.T.w / 2 - self.container.T.x, self.container.T.h / 2 - self.container.T.y
				shift_point(p, t)
			else
				t.x, t.y = -self.container.T.x, -self.container.T.y
				shift_point(p, t)
			end
		end

		if math.abs(T.r) < 0.1 then
			return p.x >= T.x - buffer and p.y >= T.y - buffer
				and p.x <= T.x + T.w + buffer and p.y <= T.y + T.h + buffer
		end

		rot.cos, rot.sin = math.cos(T.r + math.pi / 2), math.sin(T.r + math.pi / 2)
		p.x, p.y = p.x - (T.x + 0.5 * T.w), p.y - (T.y + 0.5 * T.h)
		t.x, t.y = p.y * rot.cos - p.x * rot.sin, p.y * rot.sin + p.x * rot.cos
		p.x, p.y = t.x + (T.x + 0.5 * T.w), t.y + (T.y + 0.5 * T.h)

		return p.x >= T.x - buffer and p.y >= T.y - buffer
			and p.x <= T.x + T.w + buffer and p.y <= T.y + T.h + buffer
	end

	function Node:set_offset(point, kind)
		self.ARGS.set_offset_point = self.ARGS.set_offset_point or {}
		self.ARGS.set_offset_translation = self.ARGS.set_offset_translation or {}
		local p = self.ARGS.set_offset_point
		local t = self.ARGS.set_offset_translation

		p.x, p.y = point.x, point.y
		t.x, t.y = -self.container.T.w / 2, -self.container.T.h / 2
		shift_point(p, t)
		rotate_point(p, self.container.T.r)
		t.x, t.y = self.container.T.w / 2 - self.container.T.x, self.container.T.h / 2 - self.container.T.y
		shift_point(p, t)

		if kind == "Click" then
			self.click_offset.x = p.x - self.T.x
			self.click_offset.y = p.y - self.T.y
		elseif kind == "Hover" then
			self.hover_offset.x = p.x - self.T.x
			self.hover_offset.y = p.y - self.T.y
		end
	end

	function Node:put_focused_cursor()
		local units = G.TILESCALE * G.TILESIZE
		return (self.T.x + self.T.w / 2 + self.container.T.x) * units,
			(self.T.y + self.T.h / 2 + self.container.T.y) * units
	end

	function Node:fast_mid_dist(other_node)
		return math.sqrt((other_node.T.x + 0.5 * other_node.T.w) - (self.T.x + self.T.w)) ^ 2
			+ ((other_node.T.y + 0.5 * other_node.T.h) - (self.T.y + self.T.h)) ^ 2
	end
end
