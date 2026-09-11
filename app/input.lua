-- LÖVE input callbacks. InputController owns input state and UI focus resolution.

local BridgeRuntime = require("app.runtime")

local function game()
	return BridgeRuntime.game()
end

---@param key string
function love.keypressed(key)
	local g = game()
	if not g then return end
	if not _RELEASE_MODE and g.keybind_mapping[key] then
		love.gamepadpressed(g.INPUT.keyboard_controller, g.keybind_mapping[key])
	else
		g.INPUT:set_HID_flags("mouse")
		g.INPUT:key_press(key)
	end
end

---@param key string
function love.keyreleased(key)
	local g = game()
	if not g then return end
	if not _RELEASE_MODE and g.keybind_mapping[key] then
		love.gamepadreleased(g.INPUT.keyboard_controller, g.keybind_mapping[key])
	else
		g.INPUT:set_HID_flags("mouse")
		g.INPUT:key_release(key)
	end
end

function love.gamepadpressed(joystick, button)
	local g = game()
	if not g then return end
	button = g.button_mapping[button] or button
	g.INPUT:set_gamepad(joystick)
	g.INPUT:set_HID_flags("button", button)
	g.INPUT:button_press(button)
end

function love.gamepadreleased(joystick, button)
	local g = game()
	if not g then return end
	button = g.button_mapping[button] or button
	g.INPUT:set_gamepad(joystick)
	g.INPUT:set_HID_flags("button", button)
	g.INPUT:button_release(button)
end

---@param button number
---@param touch boolean|nil
function love.mousepressed(x, y, button, touch)
	local g = game()
	if not g then return end
	g.INPUT:set_HID_flags(touch and "touch" or "mouse")
	if button == 1 then
		g.INPUT:queue_L_cursor_press(x, y)
	elseif button == 2 then
		g.INPUT:queue_R_cursor_press(x, y)
	end
end

function love.mousereleased(x, y, button)
	local g = game()
	if not g then return end
	if button == 1 then
		g.INPUT:L_cursor_release(x, y)
	end
end

function love.mousemoved()
	local g = game()
	if not g then return end
	g.INPUT.last_touch_time = g.INPUT.last_touch_time or -1
	if next(love.touch.getTouches()) ~= nil then
		g.INPUT.last_touch_time = g.TIMERS.UPTIME
	end

	local recently_touched = g.INPUT.last_touch_time > g.TIMERS.UPTIME - 0.2
	g.INPUT:set_HID_flags(recently_touched and "touch" or "mouse")
end

--- Ignore small analog-stick drift when selecting the active input device.
function love.joystickaxis(joystick, _, value)
	local g = game()
	if not g then return end
	if math.abs(value) > 0.2 and joystick:isGamepad() then
		g.INPUT:set_gamepad(joystick)
		g.INPUT:set_HID_flags("axis")
	end
end

return true
