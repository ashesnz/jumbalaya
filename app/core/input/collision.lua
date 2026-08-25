return function(InputRouter)
function InputRouter:get_cursor_collision(cursor_trans)
	self.collision_list = clear_table(self.collision_list)
	self.nodes_at_cursor = clear_table(self.nodes_at_cursor)

	if self.COYOTE_FOCUS then return end

	if self.dragging.target then
		self.dragging.target.states.collide.is = true
		self.nodes_at_cursor[#self.nodes_at_cursor + 1] = self.dragging.target
		self.collision_list[#self.collision_list + 1] = self.dragging.target
	end

	-- Early-out: nothing drawn, or cursor outside the padded room rect.
	if not G.HIT_ORDER[1]
		or cursor_trans.x - G.ROOM.T.x < -G.DRAW_HASH_BUFF or cursor_trans.x - G.ROOM.T.x > G.TILE_W + G.DRAW_HASH_BUFF
		or cursor_trans.y - G.ROOM.T.y < -G.DRAW_HASH_BUFF or cursor_trans.y - G.ROOM.T.y > G.TILE_H + G.DRAW_HASH_BUFF then
		return
	end

	for i = #G.HIT_ORDER, 1, -1 do
		local v = G.HIT_ORDER[i]
		if v and v.collides_with_point and v:collides_with_point(cursor_trans) and not v.REMOVED then
			self.nodes_at_cursor[#self.nodes_at_cursor + 1] = v
			if v.states and v.states.collide and v.states.collide.can then
				v.states.collide.is = true
				self.collision_list[#self.collision_list + 1] = v
			end
		end
	end
end

--- Picks this frame's hover candidate from the collision list (or the
--- gamepad-focus target). Falls back to G.ROOM under locks/interrupts.
function InputRouter:set_cursor_hover()
	self.hover_state.T = self.hover_state.T or {}
	self.hover_state.T.x, self.hover_state.T.y = G.POINTER.T.x, G.POINTER.T.y
	self.hover_state.time = G.TIMERS.TOTAL

	self.hover_state.prev_target = self.hover_state.target
	self.hover_state.target = nil

	if self.interrupt.focus
		or ((self.locked) and (not G.SETTINGS.paused or G.screenwipe))
		or self.locks.frame
		or self.COYOTE_FOCUS then
		self.hover_state.target = G.ROOM
		return
	end

	if self.HID.controller and self.focused.target and self.focused.target.states.hover.can then
		-- Dpad/axis focus must still actually collide to count as hovered.
		if (self.HID.dpad or self.HID.axis_cursor) and self.focused.target.states.collide.is then
			self.hover_state.target = self.focused.target
		else
			for _, v in ipairs(self.collision_list) do
				if v.states.hover.can then
					self.hover_state.target = v
					break
				end
			end
		end
	else
		for _, v in ipairs(self.collision_list) do
			if v.states.hover.can and (not v.states.drag.is or self.HID.touch) then
				self.hover_state.target = v
				break
			end
		end
	end

	if not self.hover_state.target or (self.dragging.target and not self.HID.touch) then
		self.hover_state.target = G.ROOM
	end
	if self.hover_state.target ~= self.hover_state.prev_target then
		self.hover_state.handled = false
	end
end
end
