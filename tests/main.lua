--[[ Root shim — prefer: love games/jumbalaya tests ]]

function love.load()
	print("Redirecting to games/jumbalaya test suite...")
	local ok = os.execute('love "games/jumbalaya" tests')
	if love.event and love.event.quit then
		love.event.quit(ok and 0 or 1)
	else
		os.exit(ok and 0 or 1)
	end
end
