return function(InputRouter)
function InputRouter:button_press_update(button, dt)
	if self.locks.frame then return end
	self.held_button_times[button] = 0
	self.interrupt.focus = false

	-- Widget capture (cycles/tabs/sliders/drag reorder) eats dpad navigation.
	if not self:capture_focused_input(button, 'press', dt) then
		if button == "dpup" then self:navigate_focus('U') end
		if button == "dpdown" then self:navigate_focus('D') end
		if button == "dpleft" then self:navigate_focus('L') end
		if button == "dpright" then self:navigate_focus('R') end
	end

	if ((self.locked) and not G.SETTINGS.paused) or self.locks.frame or self.frame_buttonpress then return end
	self.frame_buttonpress = true

	local registry = self.button_registry[button]
	if registry and registry[1] and not registry[1].node.under_overlay then
		registry[1].click = true
	else
		if button == 'start' and G.STATE == G.STATES.SPLASH then
			G:discard_run()
			G:open_main_menu()
		end
		if button == "a" then
			-- Focused sliders handle their own activation in pure-controller mode.
			local focused_args = self.focused.target and self.focused.target.config
				and self.focused.target.config.focus_args
			if not (focused_args and focused_args.type == 'slider'
				and not G.INPUT.HID.mouse and not G.INPUT.HID.axis_cursor) then
				self:L_cursor_press()
			end
		end
		if button == 'b' then
			if G.hand and self.focused.target and self.focused.target.area == G.hand then
				self:queue_R_cursor_press()
			else
				self.interrupt.focus = true
			end
		end
	end
end

function InputRouter:button_hold_update(button, dt)
	if ((self.locked) and not G.SETTINGS.paused) or self.locks.frame or self.frame_buttonpress then return end
	self.frame_buttonpress = true

	if self.held_button_times[button] then
		self.held_button_times[button] = self.held_button_times[button] + dt
		self:capture_focused_input(button, 'hold', dt)
	end

	-- D-pad auto-repeat: slow first repeat (0.3 s) then fast (every 0.1 s).
	if (button == 'dpleft' or button == 'dpright' or button == 'dpup' or button == 'dpdown') and not self.no_holdcap then
		self.repress_timer = self.repress_timer or 0.3
		if self.held_button_times[button] and self.held_button_times[button] > self.repress_timer then
			self.repress_timer = 0.1
			self.held_button_times[button] = 0
			self:button_press_update(button, dt)
		end
	end
end

function InputRouter:button_release_update(button, dt)
	if not self.held_button_times[button] then return end
	self.repress_timer = 0.3
	self.held_button_times[button] = nil
	if button == 'a' then
		self:L_cursor_release()
	end
end

--- Keyboard phase: normalize keypad/enter aliases, service the text-input
--- capture hook, handle escape/menu semantics, then delegate app actions.
function InputRouter:key_press_update(key, dt)
	if self.locks.frame then return end
	if string.sub(key, 1, 2) == 'kp' then key = string.sub(key, 3) end
	if key == 'enter' then key = 'return' end

	if self.text_capture then
		if key == "escape" then
			self.text_capture = nil
		elseif key == "capslock" then
			self.capslock = not self.capslock
		else
			G.FUNCS.text_field_key{
				e = self.text_capture,
				key = key,
				caps = self.held_keys["lshift"] or self.held_keys["rshift"],
			}
		end
		return
	end

	if key == "escape" then
		if G.STATE == G.STATES.SPLASH then
			G:discard_run()
			G:open_main_menu()
		elseif not G.OVERLAY_MENU then
			G.FUNCS:options()
		elseif not G.OVERLAY_MENU.config.no_esc then
			G.FUNCS:exit_overlay_menu()
		end
	end

	if ((self.locked) and not G.SETTINGS.paused) or self.locks.frame or self.frame_buttonpress then return end
	self.frame_buttonpress = true
	self.held_key_times[key] = 0

	if InputRouter._input_actions then
		InputRouter._input_actions.key_press(self, key)
	end
end

function InputRouter:key_hold_update(key, dt)
	if ((self.locked) and not G.SETTINGS.paused) or self.locks.frame or self.frame_buttonpress then return end
	if self.held_key_times[key] and key == "r" and not G.SETTINGS.paused then
		if self.held_key_times[key] > 0.7 then
			if InputRouter._input_actions then
				InputRouter._input_actions.key_hold(self, key, dt)
			end
		else
			self.held_key_times[key] = self.held_key_times[key] + dt
		end
	end
end

function InputRouter:key_release_update(key, dt)
	if ((self.locked) and not G.SETTINGS.paused) or self.locks.frame or self.frame_buttonpress then return end
	self.frame_buttonpress = true
	if InputRouter._input_actions then
		InputRouter._input_actions.key_release(self, key)
	end
end
end
