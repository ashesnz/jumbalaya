--[[
	jumbalaya-engine/audio.lua - AudioService interface and Love2D adapter wrapping app/core/audio/sound.lua.
]]

require("app.core.audio.sound")

---@class AudioService
local AudioService = {}
AudioService.__index = AudioService

function AudioService.new()
	return setmetatable({}, AudioService)
end

function AudioService:play(id, opts)
	opts = opts or {}
	if play_sfx then
		play_sfx(id, opts.rate, opts.gain)
	end
end

return AudioService
