
local Colour = require("jumbalaya-engine.util.colour")
local NodeTransform = require("jumbalaya-engine.graphics.node_transform")
local HitOrder = require("jumbalaya-engine.graphics.hit_order")
local DropShadow = require("jumbalaya-engine.graphics.drop_shadow")
local shell = require("jumbalaya-engine.shell")
local game = shell.game
local button_colours = {}
return function(Target)
function Target:draw_self()
	if not self.states.visible then
		if self.config.force_focus then HitOrder.track_hit_target(self) end
		return
	end

	if self.config.force_focus or self.config.force_collision or self.config.button_host
		or self.config.button or self.states.collideable then
		HitOrder.track_hit_target(self)
	end

	local button_active = true
	local button_being_pressed = false
	local sx, sy = DropShadow.pixels(game().TILESIZE)

	if self.config.button or self.config.button_host then
		self.parallax_shift.x = (self.parent and self.parent ~= self.panel and self.parent.parallax_shift.x) or 0
		self.parallax_shift.y = (self.parent and self.parent ~= self.panel and self.parent.parallax_shift.y) or 0

		-- Pressed-in look: recent click, or hovered/dragged while held.
		if self.config.button and ((self.last_clicked and self.last_clicked > game().TIMERS.REAL - 0.1)
			or ((self.config.button and (self.states.hovering or self.states.dragging))
				and game().INPUT.pointer_held)) then
			self.parallax_shift.y = self.parallax_shift.y + 0.05 * (self.config.button_dist or 1)
			button_being_pressed = true
		end

		-- Grey-out text nested under a disabled button wrapper.
		if self.config.button_host and not self.config.button_host.config.button then button_active = false end
	end

	if self.config.colour[4] > 0.01 then
		if self.ui_kind == game().UI.TEXT and self.config.scale then
			if not self.config.text_drawable then
				self:update_text()
			end
			if not self.config.text_drawable then
				return
			end
			-- Text: optional drop shadow pass at depth 0.97, then the glyph.
			local font_obj = self.config.font or self.config.lang.font
			local shadow_tx = sx / game().TILESIZE
			local shadow_ty = sy / game().TILESIZE

			if (self.config.button_host and button_active)
				or (not self.config.button_host and self.config.shadow and game().SETTINGS.GRAPHICS.shadows == 'On') then
				NodeTransform.push_node_transform(self, 0.97)
				if self.config.vert then love.graphics.translate(0, self.VT.h); love.graphics.rotate(-math.pi / 2) end
				if (self.config.shadow or (self.config.button_host and button_active))
					and game().SETTINGS.GRAPHICS.shadows == 'On' then
					love.graphics.setColor(DropShadow.rgba(self.config.colour[4]))
					love.graphics.draw(
						self.config.text_drawable,
						font_obj.TEXT_OFFSET.x * (self.config.scale or 1) * font_obj.FONTSCALE / game().TILESIZE + (self.config.vert and -shadow_ty or shadow_tx),
						font_obj.TEXT_OFFSET.y * (self.config.scale or 1) * font_obj.FONTSCALE / game().TILESIZE + (self.config.vert and shadow_tx or shadow_ty),
						0,
						self.config.scale * font_obj.squish * font_obj.FONTSCALE / game().TILESIZE,
						self.config.scale * font_obj.FONTSCALE / game().TILESIZE)
				end
				love.graphics.pop()
			end

			NodeTransform.push_node_transform(self, 1)
			if self.config.vert then love.graphics.translate(0, self.VT.h); love.graphics.rotate(-math.pi / 2) end
			if not button_active then
				love.graphics.setColor(game().C.UI.TEXT_INACTIVE)
			else
				love.graphics.setColor(self.config.colour)
			end
			love.graphics.draw(
				self.config.text_drawable,
				font_obj.TEXT_OFFSET.x * self.config.scale * font_obj.FONTSCALE / game().TILESIZE,
				font_obj.TEXT_OFFSET.y * self.config.scale * font_obj.FONTSCALE / game().TILESIZE,
				0,
				self.config.scale * font_obj.squish * font_obj.FONTSCALE / game().TILESIZE,
				self.config.scale * font_obj.FONTSCALE / game().TILESIZE)
			love.graphics.pop()

		elseif self.ui_kind == game().UI.BOX or self.ui_kind == game().UI.COLUMN or self.ui_kind == game().UI.ROW or self.ui_kind == game().UI.ROOT then
			NodeTransform.push_node_transform(self, 1)
			love.graphics.scale(1 / game().TILESIZE)

			-- Drop shadow: one offset + alpha.
			if self.config.shadow and game().SETTINGS.GRAPHICS.shadows == 'On' then
				if self.config.shadow_colour then
					love.graphics.setColor(self.config.shadow_colour)
				else
					love.graphics.setColor(DropShadow.rgba(self.config.colour[4]))
				end
				if self.config.r and self.VT.w > 0.01 then
					self:draw_pixellated_rect('shadow')
				else
					love.graphics.rectangle('fill', sx, sy, self.VT.w * game().TILESIZE, self.VT.h * game().TILESIZE)
				end
			end

			-- Press-in squash.
			love.graphics.scale(button_being_pressed and 0.975 or 1)

			-- Embossed lip above the fill surface.
			if self.config.emboss then
				love.graphics.setColor(Colour.shade(self.config.colour, self.states.hovering and 0.5 or 0.3, true))
				self:draw_pixellated_rect('emboss', nil, self.config.emboss)
			end

			-- Fill layers: base colour (greyed during button_delay), plus a
			-- hover/click overlay tint.
			local collided_button = self.config.button_host or self
			button_colours[1] = self.config.button_delay
				and Colour.blend_colours(self.config.colour, game().C.L_BLACK, 0.5) or self.config.colour
			button_colours[2] =
				(((collided_button.config.hover and collided_button.states.hovering)
					or (collided_button.last_clicked and collided_button.last_clicked > game().TIMERS.REAL - 0.1))
				and game().C.UI.HOVER or nil)

			for layer, colour in ipairs(button_colours) do
				love.graphics.setColor(colour)
				if self.config.glossy and layer == 1 then
					-- Glossy normally needs stencils, which canvas rendering may
					-- not provide; fall back to the standard rounded fill.
					if self.config.r and self.VT.w > 0.01 then
						self:draw_pixellated_rect('fill')
					else
						love.graphics.rectangle('fill', 0, 0, self.VT.w * game().TILESIZE, self.VT.h * game().TILESIZE)
					end
				elseif self.config.r and self.VT.w > 0.01 then
					if self.config.button_delay then
						-- Delay bar: grey track filling left-to-right.
						love.graphics.setColor(game().C.GREY)
						self:draw_pixellated_rect('fill')
						love.graphics.setColor(colour)
						self:draw_pixellated_rect('fill', nil, nil, self.config.button_delay_progress)
					elseif self.config.progress_bar then
						local progress = self.config.progress_bar
						love.graphics.setColor(progress.empty_col or game().C.GREY)
						self:draw_pixellated_rect('fill')
						love.graphics.setColor(progress.filled_col or game().C.BLUE)
						self:draw_pixellated_rect('fill', nil, nil,
							progress.ref_table[progress.ref_value] / progress.max)
					else
						self:draw_pixellated_rect('fill')
					end
				else
					love.graphics.rectangle('fill', 0, 0, self.VT.w * game().TILESIZE, self.VT.h * game().TILESIZE)
				end
			end
			love.graphics.pop()

		elseif self.ui_kind == game().UI.OBJECT and self.config.object then
			-- Flash a ring while the embedded object has focus.
			if self.config.focus_with_object and self.config.object.states.focused then
				self.object_focus_timer = self.object_focus_timer or game().TIMERS.REAL
				local lw = 50 * math.max(0, self.object_focus_timer - game().TIMERS.REAL + 0.3)^2
				NodeTransform.push_node_transform(self, 1)
				love.graphics.scale(1 / game().TILESIZE)
				love.graphics.setLineWidth(lw + 1.5)
				love.graphics.setColor(Colour.with_alpha(game().C.WHITE, 0.2 * lw, true))
				self:draw_pixellated_rect('fill')
				love.graphics.setColor(self.config.colour[4] > 0
					and Colour.blend_colours(game().C.WHITE, self.config.colour, 0.8) or game().C.WHITE)
				self:draw_pixellated_rect('line')
				love.graphics.pop()
			else
				self.object_focus_timer = nil
			end
			self.config.object:draw()
		end
	end

	self:draw_self_decor()
	self:draw_boundingrect()
end
end
