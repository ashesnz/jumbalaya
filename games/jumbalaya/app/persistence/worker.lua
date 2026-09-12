--[[ app/persistence/worker.lua - love.thread entry for disk writes ]]

require "love.system"
require "love.timer"
require "love.thread"
require 'love.filesystem'

if love.system.getOS() == 'OS X' then jit.off() end

local root = love.filesystem.getSource()
package.path = root .. "/../../packages/?.lua;"
	.. root .. "/../../packages/?/init.lua;"
	.. root .. "/?.lua;"
	.. root .. "/?/init.lua;"
	.. package.path

require "jumbalaya-engine.object"
require "jumbalaya-engine.util.pack"

require("jumbalaya-engine.persistence.worker").run()
