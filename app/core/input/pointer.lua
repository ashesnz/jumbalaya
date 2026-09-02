return function(InputRouter)
function InputRouter:queue_L_cursor_press(x, y)
	if self.locks.frame then return end
	if G.STATE == G.STATES.SPLASH then
		self:key_press('escape')
	end
	self.deferred_press = {x = x, y = y}
end

--- Right press: clears hand selections (gated against mid-play states).
function InputRouter:queue_R_cursor_press(x, y)
	if self.locks.frame then return end
	if not G.SETTINGS.paused and G.hand and G.hand.selected[1] then
		if self.locked or self.locks.frame then
			return
		end
		G.hand:clear_selection()
	end
end

function InputRouter:L_cursor_press(x, y)
	x = x or self.cursor_position.x
	y = y or self.cursor_position.y

	if ((self.locked) and (not G.SETTINGS.paused or G.screenwipe)) or self.locks.frame then return end

	self.press_state.T = {x = x / (G.TILESCALE * G.TILESIZE), y = y / (G.TILESCALE * G.TILESIZE)}
	self.press_state.time = G.TIMERS.TOTAL
	self.press_state.handled = false
	self.press_state.target = nil
	self.pointer_held = true

	-- Prefer the hovered node; fall back to focus, then to anything draggable.
	local press_node = (self.HID.touch and self.hover_state.target)
		or self.hovering.target
		or self.focused.target

	if press_node then
		self.press_state.target = press_node.states.click.can and press_node or press_node:can_drag() or nil
	end
	if self.press_state.target == nil then
		self.press_state.target = G.ROOM
	end
end

function InputRouter:L_cursor_release(x, y)
	x = x or self.cursor_position.x
	y = y or self.cursor_position.y

	if ((self.locked) and (not G.SETTINGS.paused or G.screenwipe)) or self.locks.frame then return end

	self.release_state.T = {x = x / (G.TILESCALE * G.TILESIZE), y = y / (G.TILESCALE * G.TILESIZE)}
	self.release_state.time = G.TIMERS.TOTAL
	self.release_state.handled = false
	self.release_state.target = nil
	self.pointer_held = false

	self.release_state.target = self.hovering.target or self.focused.target
	if self.release_state.target == nil then
		self.release_state.target = G.ROOM
	end
end
end
