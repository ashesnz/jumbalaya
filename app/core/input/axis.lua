return function(InputRouter)
function InputRouter:handle_axis_buttons()
	for _, v in pairs(G.INPUT.axis_buttons) do
		if v.previous ~= '' and (v.current == '' or v.previous ~= v.current) then
			G.INPUT:button_release(v.previous)
		end
		if v.current ~= '' and v.previous ~= v.current then
			G.INPUT:button_press(v.current)
		end
	end
end

--- Samples sticks/triggers each frame and decides what they mean:
--- left stick = cursor while dragging else a d-pad; right stick always a
--- cursor; triggers are buttons with hysteresis. Returns the HID
--- interpretation ('axis_cursor' | 'button') or nil.
function InputRouter:update_axis(dt)
	local axis_interpretation = nil

	-- Advance every axis slot; sticks blank out (hysteresis handled below)
	-- while triggers keep their previous value unless they fall below 0.3.
	for _, slot in pairs(self.axis_buttons) do
		slot.previous = slot.current
		slot.current = ''
	end
	self.axis_buttons.l_trig.current = self.axis_buttons.l_trig.previous
	self.axis_buttons.r_trig.current = self.axis_buttons.r_trig.previous

	if self.HID.controller then
		---------------------------------------------------------------
		-- Left thumbstick
		---------------------------------------------------------------
		local lx = self.GAMEPAD.object:getGamepadAxis('leftx')
		local ly = self.GAMEPAD.object:getGamepadAxis('lefty')

		if self.dragging.target and math.abs(lx) + math.abs(ly) > 0.1 then
			-- Cursor mode (10% per-axis deadzone with rescale).
			axis_interpretation = 'axis_cursor'
			if math.abs(lx) < 0.1 then lx = 0 end
			if math.abs(ly) < 0.1 then ly = 0 end
			lx = lx + (lx > 0 and -0.1 or 0) + (lx < 0 and 0.1 or 0)
			ly = ly + (ly > 0 and -0.1 or 0) + (ly < 0 and 0.1 or 0)

			G.POINTER.T.x = G.POINTER.T.x + dt * lx * self.axis_cursor_speed
			G.POINTER.T.y = G.POINTER.T.y + dt * ly * self.axis_cursor_speed
			G.POINTER.VT.x = G.POINTER.T.x
			G.POINTER.VT.y = G.POINTER.T.y
			self.cursor_position.x = G.POINTER.T.x * (G.TILESCALE * G.TILESIZE)
			self.cursor_position.y = G.POINTER.T.y * (G.TILESCALE * G.TILESIZE)
		else
			-- D-pad mode: dominant direction past 0.5, hysteresis below 0.3.
			self.axis_buttons.l_stick.current = self.axis_buttons.l_stick.previous
			if math.abs(lx) + math.abs(ly) > 0.5 then
				axis_interpretation = 'button'
				self.axis_buttons.l_stick.current =
					math.abs(lx) > math.abs(ly)
					and (lx > 0 and 'dpright' or 'dpleft')
					or (ly > 0 and 'dpdown' or 'dpup')
			elseif math.abs(lx) + math.abs(ly) < 0.3 then
				self.axis_buttons.l_stick.current = ''
			end
		end

		---------------------------------------------------------------
		-- Right thumbstick (always a cursor)
		---------------------------------------------------------------
		local rx = self.GAMEPAD.object:getGamepadAxis('rightx')
		local ry = self.GAMEPAD.object:getGamepadAxis('righty')
		G.DEADZONE = 0.2
		local mag = math.sqrt(math.abs(rx)^2 + math.abs(ry)^2)
		G.DEBUG_VALUE = mag

		if mag > G.DEADZONE then
			axis_interpretation = 'axis_cursor'
			if math.abs(rx) < G.DEADZONE then rx = 0 end
			if math.abs(ry) < G.DEADZONE then ry = 0 end
			rx = rx + (rx > 0 and -G.DEADZONE or 0) + (rx < 0 and G.DEADZONE or 0)
			ry = ry + (ry > 0 and -G.DEADZONE or 0) + (ry < 0 and G.DEADZONE or 0)

			G.POINTER.T.x = G.POINTER.T.x + dt * rx * self.axis_cursor_speed
			G.POINTER.T.y = G.POINTER.T.y + dt * ry * self.axis_cursor_speed
			G.POINTER.VT.x = G.POINTER.T.x
			G.POINTER.VT.y = G.POINTER.T.y
			self.cursor_position.x = G.POINTER.T.x * (G.TILESCALE * G.TILESIZE)
			self.cursor_position.y = G.POINTER.T.y * (G.TILESCALE * G.TILESIZE)
		end

		---------------------------------------------------------------
		-- Triggers (buttons with a 0.5 press / 0.3 release band)
		---------------------------------------------------------------
		local lt = self.GAMEPAD.object:getGamepadAxis('triggerleft')
		local rt = self.GAMEPAD.object:getGamepadAxis('triggerright')

		if lt > 0.5 then
			self.axis_buttons.l_trig.current = 'triggerleft'
		elseif lt < 0.3 then
			self.axis_buttons.l_trig.current = ''
		end
		if rt > 0.5 then
			self.axis_buttons.r_trig.current = 'triggerright'
		elseif rt < 0.3 then
			self.axis_buttons.r_trig.current = ''
		end

		if self.axis_buttons.r_trig.current ~= '' or self.axis_buttons.l_trig.current ~= '' then
			axis_interpretation = axis_interpretation or 'button'
		end

		self:handle_axis_buttons()
	end

	if axis_interpretation then self.interrupt.focus = false end

	return axis_interpretation
end
end
