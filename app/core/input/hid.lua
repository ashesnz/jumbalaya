return function(InputRouter)
function InputRouter:set_HID_flags(HID_type, button)
	if HID_type == 'axis' then
		self.HID.controller = true
		self.HID.last_type = 'axis'
	elseif HID_type and HID_type ~= self.HID.last_type then
		self.HID.dpad = HID_type == 'button'
		self.HID.pointer = HID_type == 'mouse' or HID_type == 'axis_cursor' or HID_type == 'touch'
		self.HID.controller = HID_type == 'button' or HID_type == 'axis_cursor'
		self.HID.mouse = HID_type == 'mouse'
		self.HID.touch = HID_type == 'touch'
		self.HID.axis_cursor = HID_type == 'axis_cursor'
		self.HID.last_type = HID_type

		love.mouse.setVisible(self.HID.mouse)
	end

	if not self.HID.controller then
		self.GAMEPAD_CONSOLE = ''
		self.GAMEPAD.object = nil
		self.GAMEPAD.mapping = nil
		self.GAMEPAD.name = nil
	end
end

--- Follows the OS pointer while in mouse/touch mode; clears gamepad focus.
function InputRouter:set_cursor_position()
	if not (self.HID.mouse or self.HID.touch) then return end

	self.interrupt.focus = false
	if self.focused.target then
		self.focused.target.states.focus.is = false
		self.focused.target = nil
	end

	self.cursor_position.x, self.cursor_position.y = love.mouse.getPosition()
	G.POINTER.T.x = self.cursor_position.x / (G.TILESCALE * G.TILESIZE)
	G.POINTER.T.y = self.cursor_position.y / (G.TILESCALE * G.TILESIZE)
	G.POINTER.VT.x = G.POINTER.T.x
	G.POINTER.VT.y = G.POINTER.T.y
end
end
