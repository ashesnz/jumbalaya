--[[
	Jumbalaya LÖVE entry point.

	The app package keeps framework callbacks separated by responsibility:
	  bootstrap.lua     dependency-ordered legacy module loading
	  lifecycle.lua     frame loop and load/update/draw/quit callbacks
	  input.lua         keyboard, pointer, and gamepad callbacks
	  error_handler.lua crash reporting and fallback error UI
	  window.lua        resize and viewport reconstruction
]]

io.stdout:setvbuf("no")

local runtime_config = require "word_game.config.runtime"
_RELEASE_MODE = runtime_config.RELEASE_MODE
_DEMO = runtime_config.DEMO

-- Some engine behavior differs under JIT. This retains the existing policy of
-- disabling it on the currently supported runtime.
local os_name = love.system.getOS()
if os_name == "OS X" or os_name == "iOS" then
	jit.off()
end

-- Earliest possible landscape lock on mobile (before bootstrap / launch).
if os_name == "iOS" or os_name == "Android" then
	require("app.core.platform.window").lock_landscape_orientation()
end

require "app.bootstrap"
math.randomseed(G.SEED)

require "app.core.session.lifecycle"
require "app.input"
require "app.error_handler"
require "app.core.platform.window"

