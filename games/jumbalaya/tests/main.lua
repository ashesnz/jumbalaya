--[[ tests/main.lua
     Entry point for running unit tests via `love tests`.
]]

function love.load()
	local runner = require("tests.runner")
	local success = runner.run()
	if love.event and love.event.quit then
		love.event.quit(success and 0 or 1)
	else
		os.exit(success and 0 or 1)
	end
end
