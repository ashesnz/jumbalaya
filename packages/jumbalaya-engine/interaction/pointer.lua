return function(InputRouter)
local shell = require("jumbalaya-engine.shell")
local function g() return shell.game() end


local function tile_xy(screen_x, screen_y)
	local units = g().TILESCALE * g().TILESIZE
	return screen_x / units, screen_y / units
end

local function sync_pointer_screen(self, screen_x, screen_y)
	local tx, ty = tile_xy(screen_x, screen_y)
	self.cursor_position.x = screen_x
	self.cursor_position.y = screen_y
	g().POINTER.T.x = tx
	g().POINTER.T.y = ty
	g().POINTER.VT.x = tx
	g().POINTER.VT.y = ty
end

local function refresh_collision_at_screen(self, screen_x, screen_y)
	sync_pointer_screen(self, screen_x, screen_y)
	self:get_cursor_collision(g().POINTER.T)
	self:set_cursor_hover()
end

local function topmost_draggable(self)
	for i = #self.nodes_at_cursor, 1, -1 do
		local node = self.nodes_at_cursor[i]
		if node and node ~= g().ROOM and node.states and node.states.drag
			and node.states.drag.can and node:can_drag() then
			return node
		end
	end
	return nil
end

local function resolve_press_target(self, press_node)
	if self.HID.touch then
		if (not press_node or press_node == g().ROOM) then
			press_node = topmost_draggable(self) or press_node
		end
	end
	if not press_node or press_node == g().ROOM then
		return press_node
	end
	if press_node.states.click.can then
		return press_node
	end
	return press_node:can_drag() or nil
end

function InputRouter:queue_L_cursor_press(x, y)
	if self.locks.frame then return end
	if g().STATE == g().STATES.SPLASH then
		self:key_press('escape')
	end
	self.deferred_press = {x = x, y = y}
end

--- Right press: clears hand selections (gated against mid-play states).
function InputRouter:queue_R_cursor_press(x, y)
	if self.locks.frame then return end
	local hand = require("jumbalaya-engine.interaction.card_focus").hand_area()
	if not g().SETTINGS.paused and hand and hand.selected[1] then
		if self.locked or self.locks.frame then
			return
		end
		hand:clear_selection()
	end
end

function InputRouter:L_cursor_press(x, y)
	x = x or self.cursor_position.x
	y = y or self.cursor_position.y

	if ((self.locked) and (not g().SETTINGS.paused or g().screenwipe)) or self.locks.frame then return end

	if self.HID.touch then
		refresh_collision_at_screen(self, x, y)
	end

	local tx, ty = tile_xy(x, y)
	self.press_state.T = { x = tx, y = ty }
	self.press_state.time = g().TIMERS.TOTAL
	self.press_state.handled = false
	self.press_state.target = nil
	self.pointer_held = true

	-- Touch uses hover_state from the press-point collision pass above.
	local press_node = (self.HID.touch and self.hover_state.target)
		or self.hovering.target
		or self.focused.target

	self.press_state.target = resolve_press_target(self, press_node)
	if self.press_state.target == nil then
		self.press_state.target = g().ROOM
	end
end

function InputRouter:L_cursor_release(x, y)
	x = x or self.cursor_position.x
	y = y or self.cursor_position.y

	if ((self.locked) and (not g().SETTINGS.paused or g().screenwipe)) or self.locks.frame then return end

	if self.HID.touch then
		refresh_collision_at_screen(self, x, y)
	end

	local rx, ry = tile_xy(x, y)
	self.release_state.T = { x = rx, y = ry }
	self.release_state.time = g().TIMERS.TOTAL
	self.release_state.handled = false
	self.release_state.target = nil
	self.pointer_held = false

	self.release_state.target = self.hover_state.target
		or self.hovering.target
		or self.focused.target
	if self.release_state.target == nil then
		self.release_state.target = g().ROOM
	end
end
end
