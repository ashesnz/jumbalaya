--[[ app/sound/worker.lua - love.thread entry for audio mix ]]

require "love.audio"
require "love.sound"
require "love.system"
require "love.thread"
require "love.filesystem"

if love.system.getOS() == "OS X" then jit.off() end

local log = love.thread.getChannel("alpha_audio_log")
local ok, err = pcall(function()
	require("app.sound.install_paths")
	require("jumbalaya-engine.sound.manager")
end)
if not ok then
	log:push("error:" .. tostring(err))
end
