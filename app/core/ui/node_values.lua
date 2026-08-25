return function(Target)
function LayoutNode:set_values(_T, recalculate)
	if not recalculate or not self.T then
		AnimNode.construct(self, {T = _T})
		self.states.click.can = false
		self.states.drag.can = false
		self.static_rotation = true
	else
		self.T.x, self.T.y = _T.x, _T.y
		self.T.w, self.T.h = _T.w, _T.h
	end

	-- Interaction capability from config shape.
	if self.config.button_UIE then
		self.states.collide.can = true; self.states.hover.can = false; self.states.click.can = true
	end
	if self.config.button then
		self.states.collide.can = true; self.states.click.can = true
	end
	if self.config.on_demand_tooltip or self.config.tooltip or self.config.detailed_tooltip then
		self.states.collide.can = true
	end

	-- Every element hangs off its LayoutView as a Minor at its layout position.
	self:set_role{role_type = 'Minor', major = self.LayoutView, offset = {x = _T.x, y = _T.y}, wh_bond = 'Weak', scale_bond = 'Weak'}

	if self.config.draw_layer then
		self.LayoutView.draw_layers[self.config.draw_layer] = self
	end

	if self.config.collideable then self.states.collide.can = true end

	-- Explicit tri-state override; propagates to embedded objects.
	if self.config.can_collide ~= nil then
		self.states.collide.can = self.config.can_collide
		if self.config.object then self.config.object.states.collide.can = self.states.collide.can end
	end

	if self.ui_kind == G.UI.OBJECT and not self.config.no_role then
		self.config.object:set_role(self.config.role
			or {role_type = 'Minor', major = self, xy_bond = 'Strong', wh_bond = 'Weak', scale_bond = 'Weak'})
	end

	if self.config and self.config.ref_value and self.config.ref_table then
		self.config.prev_value = self.config.ref_table[self.config.ref_value]
	end

	if self.ui_kind == G.UI.TEXT then self.static_rotation = true end

	-- One-shot bounce requested via config (object leaves bounce the object).
	if self.config.bounce then
		if self.ui_kind == G.UI.OBJECT then
			self.config.object:pulse(0.5)
		else
			self:pulse()
		end
		self.config.bounce = false
	end

	-- Sensible default colours per node type.
	if not self.config.colour then
		if self.ui_kind == G.UI.ROOT then self.config.colour = G.C.UI.BACKGROUND_DARK end
		if self.ui_kind == G.UI.TEXT then self.config.colour = G.C.UI.TEXT_LIGHT end
		if self.ui_kind == G.UI.OBJECT then self.config.colour = G.C.WHITE end
		if self.ui_kind == G.UI.BOX or self.ui_kind == G.UI.COLUMN or self.ui_kind == G.UI.ROW then
			self.config.colour = G.C.CLEAR
		end
	end
	if not self.config.outline_colour then
		if self.ui_kind == G.UI.OBJECT then
			-- Historical quirk: O nodes route their outline default through
			-- `colour`; preserved because some definitions rely on it.
			self.config.colour = G.C.UI.OUTLINE_LIGHT
		else
			self.config.outline_colour = G.C.UI.OUTLINE_LIGHT
		end
	end

	-- Register gamepad-focus metadata exactly once per element.
	if self.config.focus_args and not self.config.focus_args.registered then
		if self.config.focus_args.button then
			G.INPUT:add_to_registry(self.config.button_UIE or self, self.config.focus_args.button)
		end
		if self.config.focus_args.snap_to then
			G.INPUT:snap_to{node = self}
		end
		if self.config.focus_args.funnel_to then
			-- Cross-link with the nearest ancestor advertising funnel_from.
			local ancestor = self.parent
			while ancestor and ancestor:is_kind(LayoutNode) do
				if ancestor.config.focus_args and ancestor.config.focus_args.funnel_from then
					ancestor.config.focus_args.funnel_from = self
					self.config.focus_args.funnel_to = ancestor
					break
				end
				ancestor = ancestor.parent
			end
		end
		self.config.focus_args.registered = true
	end

	if self.config.force_focus then self.states.collide.can = true end

	if self.config.button_delay and not self.config.button_delay_start then
		self.config.button_delay_start = G.TIMERS.REAL
		self.config.button_delay_end = G.TIMERS.REAL + self.config.button_delay
		self.config.button_delay_progress = 0
	end

	self.parallax_shift = self.parallax_shift or {x = 0, y = 0}

	-- Run func hooks immediately where they configure rather than animate.
	if self.config and self.config.func
		and (((self.config.button_UIE or self.config.button) and self.config.func ~= 'set_button_pip') or self.config.insta_func) then
		G.FUNCS[self.config.func](self)
	end
end
end
