--[[ Root shim — prefer: love games/jumbalaya tests ]]

function love.load()
	require("bootstrap_paths").install()
	local ok = require("tests.runner").run()
	if love.event and love.event.quit then
		love.event.quit(ok and 0 or 1)
	else
		os.exit(ok and 0 or 1)
	end
end
