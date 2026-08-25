local EffectsScheduler = require("app.effects.scheduler")

return function(InputRouter)
function InputRouter:update_dispatch(dt)
	-- Hover application: touch only hovers while the finger is down.
	local hover_node = self.hover_state.target
	if hover_node and hover_node.states.hover.can and (not self.HID.touch or self.pointer_held) then
		self.hovering.target = hover_node
		if self.hovering.prev_target and self.hovering.prev_target ~= hover_node then
			self.hovering.prev_target.states.hover.is = false
		end
		hover_node.states.hover.is = true
		hover_node:set_offset(self.hover_state.T, 'Hover')
	elseif (hover_node == nil or (self.HID.touch and not self.pointer_held)) and self.hovering.target then
		self.hovering.target.states.hover.is = false
		self.hovering.target = nil
	end

	------------------------------------------------------------------
	-- Dispatch to game objects
	------------------------------------------------------------------

	-- Click (word-game hook: cinematic dialogue may swallow the click).
	if not self.clicked.handled then
		local clicked = self.clicked.target
		if WORD_GAME and WORD_GAME.PlayerHost and WORD_GAME.PlayerHost.consume_stage3_ally_click() then
			self.clicked.handled = true
		elseif clicked then
			clicked:click()
			self.clicked.handled = true
		else
			self.clicked.handled = true
		end
	end

	self:process_registry()

	if self.dragging.target then
		self.dragging.target:drag()
	end

	if not self.released_on.handled and self.dragging.prev_target then
		local hovering = self.hovering.target
		if hovering and self.dragging.prev_target == hovering then
			hovering:stop_hover()
			self.hovering.target = nil
		end
		local released = self.released_on.target
		if released then released:release(self.dragging.prev_target) end
		self.released_on.handled = true
	end

	-- Hover popups: immediate for pointer devices, delayed for touch.
	if self.hovering.target then
		self.hovering.target:set_offset(self.hover_state.T, 'Hover')
		if self.hovering.prev_target ~= self.hovering.target then
			if self.hovering.target ~= self.dragging.target and not self.HID.touch then
				self.hovering.target:hover()
			elseif self.HID.touch then
				-- Touch: confirm intent with a short dwell before popping.
				local target_id = self.hovering.target.ID
				EffectsScheduler.add{
					mode = 'delayed',
					blockable = false,
					blocking = false,
					delay = G.MIN_HOVER_TIME,
					func = function()
						if self.hovering.target and target_id == self.hovering.target.ID then
							self.hovering.target:hover()
						end
						return true
					end,
				}
				if self.hovering.prev_target then self.hovering.prev_target:stop_hover() end
			end
			if self.hovering.prev_target then self.hovering.prev_target:stop_hover() end
		end
	elseif self.hovering.prev_target then
		self.hovering.prev_target:stop_hover()
	end

	-- No hover popups on the node currently being dragged (non-touch).
	if self.hovering.target and self.hovering.target == self.dragging.target and not self.HID.touch then
		self.hovering.target:stop_hover()
	end
end
end
