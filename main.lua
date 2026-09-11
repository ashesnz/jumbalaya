--[[ Root shim — prefer: love games/jumbalaya ]]

io.stdout:setvbuf("no")

require("bootstrap_paths").install()

local runtime_config = require "word_game.config.boot.runtime"
_RELEASE_MODE = runtime_config.RELEASE_MODE
_DEMO = runtime_config.DEMO

local os_name = love.system.getOS()
if os_name == "OS X" or os_name == "iOS" then
	jit.off()
end

if os_name == "iOS" or os_name == "Android" then
	require("app.core.platform.window").lock_landscape_orientation()
end

require "app.bootstrap"
math.randomseed(require("app.runtime").game().SEED)

require "app.core.session.lifecycle"
require "app.input"
require "app.error_handler"
require "app.core.platform.window"
