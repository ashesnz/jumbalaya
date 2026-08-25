return function(InputRouter)
function InputRouter:update_interact(dt)
	self:get_cursor_collision(G.POINTER.T)
	self:update_focus()
	self:set_cursor_hover()
	if self.deferred_press then
		self:L_cursor_press(self.deferred_press.x, self.deferred_press.y)
		self.deferred_press = nil
	end

	self.dragging.prev_target = self.dragging.target
	self.released_on.prev_target = self.released_on.target
	self.clicked.prev_target = self.clicked.target
	self.hovering.prev_target = self.hovering.target

	-- New press: begin hold-to-inspect when eligible, else start a drag.
	if not self.press_state.handled then
		local down_target = self.press_state.target
		local inspect = WORD_GAME and WORD_GAME.CardInspect
		if down_target and down_target.states.drag.can and inspect and inspect.can_inspect and inspect.can_inspect(down_target) then
			inspect.begin_hold(down_target)
		elseif down_target and down_target.states.drag.can then
			down_target.states.drag.is = true
			down_target:set_offset(self.press_state.T, 'Click')
			self.dragging.target = down_target
			self.dragging.handled = false
		end
		self.press_state.handled = true
	end

	-- Release: stop dragging, then classify as click vs drop-on-target.
	if not self.release_state.handled then
		if self.dragging.target then
			self.dragging.target:stop_drag()
			self.dragging.target.states.drag.is = false
			self.dragging.target = nil
		end

		if self.press_state.target then
			-- Respect per-node click timeout (scaled by game speed).
			local down = self.press_state.target
			if not down.click_timeout or down.click_timeout * G.TIME_SCALE > self.release_state.time - self.press_state.time then
				if point_distance(self.press_state.T, self.release_state.T) < G.MIN_CLICK_DIST then
					if down.states.click.can then
						self.clicked.target = down
						self.clicked.handled = false
					end
				elseif self.dragging.prev_target and self.release_state.target
					and self.release_state.target.states.release_on.can then
					self.released_on.target = self.release_state.target
					self.released_on.handled = false
				end
			end
		end
		self.release_state.handled = true
	end
end
end
