-- LÖVE input callbacks. InputController owns input state and UI focus resolution.

---@param key string
function love.keypressed(key)
	if not _RELEASE_MODE and G.keybind_mapping[key] then
		love.gamepadpressed(G.INPUT.keyboard_controller, G.keybind_mapping[key])
	else
		G.INPUT:set_HID_flags("mouse")
		G.INPUT:key_press(key)
	end
end

---@param key string
function love.keyreleased(key)
	if not _RELEASE_MODE and G.keybind_mapping[key] then
		love.gamepadreleased(G.INPUT.keyboard_controller, G.keybind_mapping[key])
	else
		G.INPUT:set_HID_flags("mouse")
		G.INPUT:key_release(key)
	end
end

function love.gamepadpressed(joystick, button)
	button = G.button_mapping[button] or button
	G.INPUT:set_gamepad(joystick)
	G.INPUT:set_HID_flags("button", button)
	G.INPUT:button_press(button)
end

function love.gamepadreleased(joystick, button)
	button = G.button_mapping[button] or button
	G.INPUT:set_gamepad(joystick)
	G.INPUT:set_HID_flags("button", button)
	G.INPUT:button_release(button)
end

---@param button number
---@param touch boolean|nil
function love.mousepressed(x, y, button, touch)
	G.INPUT:set_HID_flags(touch and "touch" or "mouse")
	if button == 1 then
		G.INPUT:queue_L_cursor_press(x, y)
	elseif button == 2 then
		G.INPUT:queue_R_cursor_press(x, y)
	end
end

function love.mousereleased(x, y, button)
	if button == 1 then
		G.INPUT:L_cursor_release(x, y)
	end
end

function love.mousemoved()
	G.INPUT.last_touch_time = G.INPUT.last_touch_time or -1
	if next(love.touch.getTouches()) ~= nil then
		G.INPUT.last_touch_time = G.TIMERS.UPTIME
	end

	local recently_touched = G.INPUT.last_touch_time > G.TIMERS.UPTIME - 0.2
	G.INPUT:set_HID_flags(recently_touched and "touch" or "mouse")
end

--- Ignore small analog-stick drift when selecting the active input device.
function love.joystickaxis(joystick, _, value)
	if math.abs(value) > 0.2 and joystick:isGamepad() then
		G.INPUT:set_gamepad(joystick)
		G.INPUT:set_HID_flags("axis")
	end
end

return true
