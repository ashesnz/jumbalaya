return function(Target)
function LayoutNode:draw_self()
	if not self.states.visible then
		if self.config.force_focus then track_hit_target(self) end
		return
	end

	if self.config.force_focus or self.config.force_collision or self.config.button_UIE
		or self.config.button or self.states.collide.can then
		track_hit_target(self)
	end

	local button_active = true
	local parallax_dist = 1.5
	local button_being_pressed = false

	if self.config.button or self.config.button_UIE then
		-- Accumulate layered parallax down the tree (+ shadow contribution).
		self.parallax_shift.x = ((self.parent and self.parent ~= self.LayoutView and self.parent.parallax_shift.x) or 0)
			+ ((self.config.shadow and 0.4 * self.shadow_parallax.x or 0) / G.TILESIZE)
		self.parallax_shift.y = ((self.parent and self.parent ~= self.LayoutView and self.parent.parallax_shift.y) or 0)
			+ ((self.config.shadow and 0.4 * self.shadow_parallax.y or 0) / G.TILESIZE)

		-- Pressed-in look: recent click, or hovered/dragged while held.
		if self.config.button and ((self.last_clicked and self.last_clicked > G.TIMERS.REAL - 0.1)
			or ((self.config.button and (self.states.hover.is or self.states.drag.is))
				and G.INPUT.pointer_held)) then
			self.parallax_shift.x = self.parallax_shift.x
				- parallax_dist * self.shadow_parallax.x / G.TILESIZE * (self.config.button_dist or 1)
			self.parallax_shift.y = self.parallax_shift.y
				- parallax_dist * self.shadow_parallax.y / G.TILESIZE * (self.config.button_dist or 1)
			parallax_dist = 0
			button_being_pressed = true
		end

		-- Grey-out text nested under a disabled button wrapper.
		if self.config.button_UIE and not self.config.button_UIE.config.button then button_active = false end
	end

	if self.config.colour[4] > 0.01 then
		if self.ui_kind == G.UI.TEXT and self.config.scale then
			-- Text: optional drop shadow pass at depth 0.97, then the glyph.
			self.ARGS.text_parallax = self.ARGS.text_parallax or {}
			local font_obj = self.config.font or self.config.lang.font
			self.ARGS.text_parallax.sx = -self.shadow_parallax.x * 0.5 / (self.config.scale * font_obj.FONTSCALE)
			self.ARGS.text_parallax.sy = -self.shadow_parallax.y * 0.5 / (self.config.scale * font_obj.FONTSCALE)

			if (self.config.button_UIE and button_active)
				or (not self.config.button_UIE and self.config.shadow and G.SETTINGS.GRAPHICS.shadows == 'On') then
				push_node_transform(self, 0.97)
				if self.config.vert then love.graphics.translate(0, self.VT.h); love.graphics.rotate(-math.pi / 2) end
				if (self.config.shadow or (self.config.button_UIE and button_active))
					and G.SETTINGS.GRAPHICS.shadows == 'On' then
					love.graphics.setColor(0, 0, 0, 0.25 * self.config.colour[4])
					love.graphics.draw(
						self.config.text_drawable,
						(font_obj.TEXT_OFFSET.x + (self.config.vert and -self.ARGS.text_parallax.sy or self.ARGS.text_parallax.sx)) * (self.config.scale or 1) * font_obj.FONTSCALE / G.TILESIZE,
						(font_obj.TEXT_OFFSET.y + (self.config.vert and self.ARGS.text_parallax.sx or self.ARGS.text_parallax.sy)) * (self.config.scale or 1) * font_obj.FONTSCALE / G.TILESIZE,
						0,
						self.config.scale * font_obj.squish * font_obj.FONTSCALE / G.TILESIZE,
						self.config.scale * font_obj.FONTSCALE / G.TILESIZE)
				end
				love.graphics.pop()
			end

			push_node_transform(self, 1)
			if self.config.vert then love.graphics.translate(0, self.VT.h); love.graphics.rotate(-math.pi / 2) end
			if not button_active then
				love.graphics.setColor(G.C.UI.TEXT_INACTIVE)
			else
				love.graphics.setColor(self.config.colour)
			end
			love.graphics.draw(
				self.config.text_drawable,
				font_obj.TEXT_OFFSET.x * self.config.scale * font_obj.FONTSCALE / G.TILESIZE,
				font_obj.TEXT_OFFSET.y * self.config.scale * font_obj.FONTSCALE / G.TILESIZE,
				0,
				self.config.scale * font_obj.squish * font_obj.FONTSCALE / G.TILESIZE,
				self.config.scale * font_obj.FONTSCALE / G.TILESIZE)
			love.graphics.pop()

		elseif self.ui_kind == G.UI.BOX or self.ui_kind == G.UI.COLUMN or self.ui_kind == G.UI.ROW or self.ui_kind == G.UI.ROOT then
			push_node_transform(self, 1)
			love.graphics.scale(1 / G.TILESIZE)

			-- Drop shadow (slightly smaller, offset by parallax direction).
			if self.config.shadow and G.SETTINGS.GRAPHICS.shadows == 'On' then
				love.graphics.scale(0.986)
				if self.config.shadow_colour then
					love.graphics.setColor(self.config.shadow_colour)
				else
					love.graphics.setColor(0, 0, 0, 0.25 * self.config.colour[4])
				end
				if self.config.r and self.VT.w > 0.01 then
					self:draw_pixellated_rect('shadow', parallax_dist)
				else
					love.graphics.rectangle('fill', -self.shadow_parallax.x * parallax_dist,
						-self.shadow_parallax.y * parallax_dist, self.VT.w * G.TILESIZE, self.VT.h * G.TILESIZE)
				end
				love.graphics.scale(1 / 0.986)
			end

			-- Press-in squash.
			love.graphics.scale(button_being_pressed and 0.975 or 1)

			-- Embossed lip above the fill surface.
			if self.config.emboss then
				love.graphics.setColor(shade(self.config.colour, self.states.hover.is and 0.5 or 0.3, true))
				self:draw_pixellated_rect('emboss', parallax_dist, self.config.emboss)
			end

			-- Fill layers: base colour (greyed during button_delay), plus a
			-- hover/click overlay tint.
			local collided_button = self.config.button_UIE or self
			self.ARGS.button_colours = self.ARGS.button_colours or {}
			self.ARGS.button_colours[1] = self.config.button_delay
				and blend_colours(self.config.colour, G.C.L_BLACK, 0.5) or self.config.colour
			self.ARGS.button_colours[2] =
				(((collided_button.config.hover and collided_button.states.hover.is)
					or (collided_button.last_clicked and collided_button.last_clicked > G.TIMERS.REAL - 0.1))
				and G.C.UI.HOVER or nil)

			for layer, colour in ipairs(self.ARGS.button_colours) do
				love.graphics.setColor(colour)
				if self.config.glossy and layer == 1 then
					-- Glossy normally needs stencils, which canvas rendering may
					-- not provide; fall back to the standard rounded fill.
					if self.config.r and self.VT.w > 0.01 then
						self:draw_pixellated_rect('fill', parallax_dist)
					else
						love.graphics.rectangle('fill', 0, 0, self.VT.w * G.TILESIZE, self.VT.h * G.TILESIZE)
					end
				elseif self.config.r and self.VT.w > 0.01 then
					if self.config.button_delay then
						-- Delay bar: grey track filling left-to-right.
						love.graphics.setColor(G.C.GREY)
						self:draw_pixellated_rect('fill', parallax_dist)
						love.graphics.setColor(colour)
						self:draw_pixellated_rect('fill', parallax_dist, nil, self.config.button_delay_progress)
					elseif self.config.progress_bar then
						local progress = self.config.progress_bar
						love.graphics.setColor(progress.empty_col or G.C.GREY)
						self:draw_pixellated_rect('fill', parallax_dist)
						love.graphics.setColor(progress.filled_col or G.C.BLUE)
						self:draw_pixellated_rect('fill', parallax_dist, nil,
							progress.ref_table[progress.ref_value] / progress.max)
					else
						self:draw_pixellated_rect('fill', parallax_dist)
					end
				else
					love.graphics.rectangle('fill', 0, 0, self.VT.w * G.TILESIZE, self.VT.h * G.TILESIZE)
				end
			end
			love.graphics.pop()

		elseif self.ui_kind == G.UI.OBJECT and self.config.object then
			-- Flash a ring while the embedded object has focus.
			if self.config.focus_with_object and self.config.object.states.focus.is then
				self.object_focus_timer = self.object_focus_timer or G.TIMERS.REAL
				local lw = 50 * math.max(0, self.object_focus_timer - G.TIMERS.REAL + 0.3)^2
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
				self.object_focus_timer = nil
			end
			self.config.object:draw()
		end
	end

	self:draw_self_decor(parallax_dist)
	self:draw_boundingrect()
end
end
