return function(InputRouter)
local BridgeRuntime = require("bridge.runtime")
local function g() return BridgeRuntime.game() end

function InputRouter:set_gamepad(_gamepad)
	if self.GAMEPAD.object == _gamepad then return end

	self.GAMEPAD.object = _gamepad
	self.GAMEPAD.mapping = _gamepad:getGamepadMappingString() or ''
	self.GAMEPAD.name = self.GAMEPAD.mapping:match("^%x*,(.-),") or ''
	local detected = self:get_console_from_gamepad(self.GAMEPAD.name)

	if self.GAMEPAD_CONSOLE ~= detected then
		self.GAMEPAD_CONSOLE = detected
		for _, v in pairs(g().LIVE.SPRITE) do
			if v.atlas == g().TEXTURE_ATLASES["gamepad_ui"] then
				v.sprite_pos.y =
					detected == 'Nintendo' and 2
					or detected == 'Playstation' and (g().F_PS4_PLAYSTATION_GLYPHS and 3 or 1)
					or 0
				v:configure_frames(v.sprite_pos.x, v.sprite_pos.y)
			end
		end
	end
end

--- Brand detection from the device name (Xbox as the default).
function InputRouter:get_console_from_gamepad(_gamepad_name)
	g().ARGS.gamepad_patterns = g().ARGS.gamepad_patterns or {
		Playstation = {"%f[%w]PS%d%f[%D]", "Sony%f[%W]", "Play[Ss]tation"},
		Nintendo = {"Wii%f[%L]", "%f[%u]S?NES%f[%U]", "%f[%l]s?nes%f[%L]", "%f[%u]Switch%f[%L]", "Joy[- ]Cons?%f[%L]"},
	}

	for brand, patterns in pairs(g().ARGS.gamepad_patterns) do
		for _, pattern in ipairs(patterns) do
			if _gamepad_name:match(pattern) then return brand end
		end
	end
	return 'Xbox'
end
end
