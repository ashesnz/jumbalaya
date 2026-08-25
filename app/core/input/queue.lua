return function(InputRouter)
function InputRouter:key_press(key)
	self.pressed_keys[key] = true
	self.held_keys[key] = true
end

function InputRouter:key_release(key)
	self.held_keys[key] = nil
	self.released_keys[key] = true
end

function InputRouter:button_press(button)
	self.pressed_buttons[button] = true
	self.held_buttons[button] = true
end

function InputRouter:button_release(button)
	self.held_buttons[button] = nil
	self.released_buttons[button] = true
end
end
