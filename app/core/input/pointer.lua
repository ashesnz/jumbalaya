return function(InputRouter)
local function tile_xy(screen_x, screen_y)
	local units = G.TILESCALE * G.TILESIZE
	return screen_x / units, screen_y / units
end

local function sync_pointer_screen(self, screen_x, screen_y)
	local tx, ty = tile_xy(screen_x, screen_y)
	self.cursor_position.x = screen_x
	self.cursor_position.y = screen_y
	G.POINTER.T.x = tx
	G.POINTER.T.y = ty
	G.POINTER.VT.x = tx
	G.POINTER.VT.y = ty
end

local function refresh_collision_at_screen(self, screen_x, screen_y)
	sync_pointer_screen(self, screen_x, screen_y)
	self:get_cursor_collision(G.POINTER.T)
	self:set_cursor_hover()
end

local function topmost_draggable(self)
	for i = #self.nodes_at_cursor, 1, -1 do
		local node = self.nodes_at_cursor[i]
		if node and node ~= G.ROOM and node.states and node.states.drag
			and node.states.drag.can and node:can_drag() then
			return node
		end
	end
	return nil
end

local function resolve_press_target(self, press_node)
	if self.HID.touch then
		if (not press_node or press_node == G.ROOM) then
			press_node = topmost_draggable(self) or press_node
		end
	end
	if not press_node or press_node == G.ROOM then
		return press_node
	end
	if press_node.states.click.can then
		return press_node
	end
	return press_node:can_drag() or nil
end

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
	if not G.SETTINGS.paused and G.dealt_letters and G.dealt_letters.selected[1] then
		if self.locked or self.locks.frame then
			return
		end
		G.dealt_letters:clear_selection()
	end
end

function InputRouter:L_cursor_press(x, y)
	x = x or self.cursor_position.x
	y = y or self.cursor_position.y

	if ((self.locked) and (not G.SETTINGS.paused or G.screenwipe)) or self.locks.frame then return end

	if self.HID.touch then
		refresh_collision_at_screen(self, x, y)
	end

	local tx, ty = tile_xy(x, y)
	self.press_state.T = { x = tx, y = ty }
	self.press_state.time = G.TIMERS.TOTAL
	self.press_state.handled = false
	self.press_state.target = nil
	self.pointer_held = true

	-- Touch uses hover_state from the press-point collision pass above.
	local press_node = (self.HID.touch and self.hover_state.target)
		or self.hovering.target
		or self.focused.target

	self.press_state.target = resolve_press_target(self, press_node)
	if self.press_state.target == nil then
		self.press_state.target = G.ROOM
	end
end

function InputRouter:L_cursor_release(x, y)
	x = x or self.cursor_position.x
	y = y or self.cursor_position.y

	if ((self.locked) and (not G.SETTINGS.paused or G.screenwipe)) or self.locks.frame then return end

	if self.HID.touch then
		refresh_collision_at_screen(self, x, y)
	end

	local rx, ry = tile_xy(x, y)
	self.release_state.T = { x = rx, y = ry }
	self.release_state.time = G.TIMERS.TOTAL
	self.release_state.handled = false
	self.release_state.target = nil
	self.pointer_held = false

	self.release_state.target = self.hover_state.target
		or self.hovering.target
		or self.focused.target
	if self.release_state.target == nil then
		self.release_state.target = G.ROOM
	end
end
end
