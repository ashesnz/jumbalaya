return function(Target)
function LayoutNode:draw_self_decor(parallax_dist)
	-- Configured outline stroke.
	if self.config.outline and self.config.outline_colour[4] > 0.01 then
		push_node_transform(self, 1)
		love.graphics.scale(1 / G.TILESIZE)
		love.graphics.setLineWidth(self.config.outline)
		if self.config.line_emboss then
			love.graphics.setColor(shade(self.config.outline_colour, self.states.hover.is and 0.5 or 0.3, true))
			self:draw_pixellated_rect('line_emboss', parallax_dist, self.config.line_emboss)
		end
		love.graphics.setColor(self.config.outline_colour)
		if self.config.r and self.VT.w > 0.01 then
			if self.config.speech_tail then
				-- Stroke the bubble outline, leaving a gap where the tail joins.
				local tw, th = self.VT.w * G.TILESIZE, self.VT.h * G.TILESIZE
				local tail = get_speech_bubble_tail(0, 0, tw, th,
					self.config.speech_tail, self.config.speech_tail_reach, self.config.speech_tail_along)
				if love.graphics.setLineStyle then love.graphics.setLineStyle('rough') end
				if love.graphics.setLineJoin then love.graphics.setLineJoin('miter') end
				self:draw_pixellated_rect_line_with_gap(parallax_dist, tail[1] - 2, tail[3] + 2, th)
				love.graphics.line(tail[1], tail[2], tail[5], tail[6], tail[3], tail[4])
				love.graphics.setLineStyle('smooth')
			else
				self:draw_pixellated_rect('line', parallax_dist)
			end
		else
			love.graphics.rectangle('line', 0, 0, self.VT.w * G.TILESIZE, self.VT.h * G.TILESIZE)
		end
		love.graphics.pop()
	end

	-- Gamepad-focus set_selected ring (animated fade-in).
	if self.states.focus.is then
		self.focus_timer = self.focus_timer or G.TIMERS.REAL
		local lw = 50 * math.max(0, self.focus_timer - G.TIMERS.REAL + 0.3)^2
		push_node_transform(self, 1)
		love.graphics.scale(1 / G.TILESIZE)
		love.graphics.setLineWidth(lw + 1.5)
		love.graphics.setColor(with_alpha(G.C.WHITE, 0.2 * lw, true))
		self:draw_pixellated_rect('fill', parallax_dist)
		love.graphics.setColor(self.config.colour[4] > 0
			and blend_colours(G.C.WHITE, self.config.colour, 0.8) or G.C.WHITE)
		self:draw_pixellated_rect('line', parallax_dist)
		love.graphics.pop()
	else
		self.focus_timer = nil
	end

	-- Speech-bubble tail fill (plus its shadow when shadows are enabled).
	if self.config.speech_tail and self.config.colour[4] > 0.01 then
		push_node_transform(self, 1)
		love.graphics.scale(1 / G.TILESIZE)
		local px, py = self.parallax_shift.x, self.parallax_shift.y
		local tw, th = self.VT.w * G.TILESIZE, self.VT.h * G.TILESIZE
		local tail_args = {self.config.speech_tail, self.config.speech_tail_reach, self.config.speech_tail_along}
		if self.config.shadow and G.SETTINGS.GRAPHICS.shadows == 'On' then
			love.graphics.setColor(0, 0, 0, 0.25 * self.config.colour[4])
			love.graphics.polygon('fill', get_speech_bubble_tail(
				px - self.shadow_parallax.x * parallax_dist * 0.5,
				py - self.shadow_parallax.y * parallax_dist * 0.5,
				tw, th, unpack(tail_args)))
		end
		love.graphics.setColor(self.config.colour)
		love.graphics.polygon('fill', get_speech_bubble_tail(px, py, tw, th, unpack(tail_args)))
		love.graphics.pop()
	end

	-- Chosen-option marker triangle (shadow pass + red marker).
	if self.config.chosen then
		push_node_transform(self, 0.98)
		love.graphics.scale(1 / G.TILESIZE)
		if self.config.shadow and G.SETTINGS.GRAPHICS.shadows == 'On' then
			love.graphics.setColor(0, 0, 0, 0.25 * self.config.colour[4])
			love.graphics.polygon('fill', pointer_triangle(
				self.parallax_shift.x - self.shadow_parallax.x * parallax_dist * 0.5,
				self.parallax_shift.y - self.shadow_parallax.y * parallax_dist * 0.5,
				self.VT.w * G.TILESIZE, self.VT.h * G.TILESIZE, self.config.chosen == 'vert'))
		end
		love.graphics.pop()

		push_node_transform(self, 1)
		love.graphics.scale(1 / G.TILESIZE)
		love.graphics.setColor(G.C.RED)
		love.graphics.polygon('fill', pointer_triangle(
			self.parallax_shift.x, self.parallax_shift.y,
			self.VT.w * G.TILESIZE, self.VT.h * G.TILESIZE, self.config.chosen == 'vert'))
		love.graphics.pop()
	end
end
end
