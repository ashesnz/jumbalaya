--[[ app/sound/worker.lua - love.thread entry for audio mix ]]

require "love.audio"
require "love.sound"
require "love.system"
require "love.thread"
require "love.filesystem"

if love.system.getOS() == "OS X" then jit.off() end

local root = love.filesystem.getSource()
package.path = root .. "/../../packages/?.lua;"
	.. root .. "/../../packages/?/init.lua;"
	.. root .. "/?.lua;"
	.. root .. "/?/init.lua;"
	.. package.path

require("jumbalaya-engine.sound.manager")
