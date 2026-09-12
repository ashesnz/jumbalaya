--[[
	Jumbalaya LÖVE entry point (games/jumbalaya).

	Run game:  love games/jumbalaya
	Run tests: love games/jumbalaya tests
	Root shim: love .  /  love tests
]]

io.stdout:setvbuf("no")

require("bootstrap_paths").install()

local game_args = love.arg and love.arg.parseGameArguments and love.arg.parseGameArguments(arg) or {}
for _, token in ipairs(game_args) do
	if token == "tests" then
		function love.load()
			local ok = require("tests.runner").run()
			if love.event and love.event.quit then
				love.event.quit(ok and 0 or 1)
			else
				os.exit(ok and 0 or 1)
			end
		end
		return
	end
end

local runtime_config = require "word_game.config.boot.runtime"
_RELEASE_MODE = runtime_config.RELEASE_MODE
_DEMO = runtime_config.DEMO

local os_name = love.system.getOS()
if os_name == "OS X" or os_name == "iOS" then
	jit.off()
end

if os_name == "iOS" or os_name == "Android" then
	require("jumbalaya-engine.adapters.love2d.window").lock_landscape_orientation()
end

require "app.bootstrap"
math.randomseed(require("app.runtime").game().SEED)

require "jumbalaya-engine.adapters.love2d.lifecycle"
require "app.input"
require "app.error_handler"
require "jumbalaya-engine.adapters.love2d.window"
