--[[ jumbalaya-engine/adapters/love2d/audio_init.lua - LÖVE audio device setup ]]

local M = {}

function M.warm()
	if not (love and love.audio) then
		return false
	end
	if love.audio.setMixWithSystem then
		love.audio.setMixWithSystem(true)
	end
	if love.audio.setVolume then
		love.audio.setVolume(1)
	end
	return true
end

return M
