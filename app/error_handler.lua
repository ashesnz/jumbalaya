-- Crash reporting and the minimal fallback UI shown after an unhandled error.

local function encode_url(value)
	local function char_to_hex(character)
		return string.format("%%%02X", string.byte(character))
	end

	return value
		:gsub("\n", "\r\n")
		:gsub("([^%w _%%%-%.~])", char_to_hex)
		:gsub(" ", "+")
end

local function relevant_trace(message)
	local file = string.sub(message, 0, string.find(message, ":") or 0)
	local function_line = string.sub(message, string.len(file) + 1)
	function_line = string.sub(function_line, 0, (string.find(function_line, ":") or 1) - 1)
	file = string.sub(file, 0, string.len(file) - 1)

	local trace = debug.traceback()
	local boot_found, function_found = false, false
	for line in string.gmatch(trace, "(.-)\n") do
		if string.match(line, "boot.lua") then
			boot_found = true
		elseif boot_found and not function_found then
			function_found = true
			trace = ""
			function_line =
				string.sub(line, (string.find(line, "in function") or 0) + 12)
				.. " line:"
				.. function_line
		end

		if boot_found and function_found then
			trace = trace .. line .. "\n"
		end
	end

	return file, function_line, trace
end

local function send_crash_report(message)
	local http_thread = love.thread.newThread([[
		local https = require("https")
		CHANNEL = love.thread.getChannel("http_channel")

		while true do
			local request = CHANNEL:demand()
			if request then
				https.request(request)
			end
		end
	]])
	local http_channel = love.thread.getChannel("http_channel")
	http_thread:start()

	local file, function_line, trace = relevant_trace(message)
	local endpoint = "https://958ha8ong3.execute-api.us-east-2.amazonaws.com/"
	local query = "?error=" .. encode_url(message)
		.. "&file=" .. encode_url(file)
		.. "&function_line=" .. encode_url(function_line)
		.. "&trace=" .. encode_url(trace)
		.. "&version=" .. G.VERSION
	http_channel:push(endpoint .. query)
end

local function ensure_error_window()
	if love.graphics.isCreated() and love.window.isOpen() then
		return true
	end

	local success, status = pcall(love.window.setMode, 800, 600)
	return success and status
end

local function error_message(message, trace)
	if not _RELEASE_MODE then
		return "Oops! Something went wrong:\n"
			.. message
			.. "\n\n"
			.. trace
			.. "\n\n---\nFull error also printed in Terminal and saved to error.log"
			.. "\nin your LÖVE save folder (see Terminal output for path)."
	end

	local crash_reports_enabled = G
		and G.SETTINGS
		and G.SETTINGS.crashreports
	if crash_reports_enabled then
		return "Oops! Something went wrong:\n"
			.. message
			.. "\n\nSince you are opted in to sending crash reports, a crash report was sent"
			.. " with useful info about what happened.\nDon't worry! There is no identifying"
			.. " or personal information. If you would like\nto opt out, change the"
			.. " 'Crash Report' setting to Off"
	end

	return "Oops! Something went wrong:\n"
		.. message
		.. "\n\nCrash Reports are set to Off. If you would like to send crash reports,"
		.. " please opt in in the Game settings.\nThese crash reports help us avoid"
		.. " issues like this in the future"
end

local function await_error_exit(message)
	while true do
		love.event.pump()

		for event, key in love.event.poll() do
			if event == "quit" or (event == "keypressed" and key == "escape") then
				return
			elseif event == "touchpressed" then
				local name = love.window.getTitle()
				if #name == 0 or name == "Untitled" then
					name = "Game"
				end
				local pressed = love.window.showMessageBox("Quit " .. name .. "?", "", { "OK", "Cancel" })
				if pressed == 1 then
					return
				end
			end
		end

		local margin = love.window.toPixels(70)
		love.graphics.clear(love.graphics.getBackgroundColor())
		love.graphics.printf(message, margin, margin, love.graphics.getWidth() - margin)
		love.graphics.present()
		love.timer.sleep(0.1)
	end
end

---@param message any
function love.errhand(message)
	if G and G.F_NO_ERROR_HAND then
		return
	end

	message = tostring(message)
	local trace = debug.traceback()
	local report = "=== Jumbalaya Error ===\n" .. message .. "\n\n" .. trace .. "\n"
	io.stderr:write(report)
	io.stderr:flush()
	print(report)

	love.filesystem.write("error.log", report)
	local save_dir = love.filesystem.getSaveDirectory()
	if save_dir then
		io.stderr:write("Error log saved to: " .. save_dir .. "/error.log\n")
		io.stderr:flush()
	end

	if G and G.SETTINGS and G.SETTINGS.crashreports and _RELEASE_MODE and G.F_CRASH_REPORTS then
		send_crash_report(message)
	end

	if not ensure_error_window() then
		return
	end

	love.mouse.setVisible(true)
	love.mouse.setGrabbed(false)
	love.mouse.setRelativeMode(false)
	for _, joystick in ipairs(love.joystick.getJoysticks()) do
		joystick:setVibration()
	end
	love.audio.stop()
	love.graphics.reset()
	love.graphics.setNewFont("resources/fonts/Outfit-Bold.ttf", 20)
	love.graphics.setBackgroundColor(G and G.C and G.C.BLACK or { 0, 0, 0, 1 })
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.clear(love.graphics.getBackgroundColor())
	love.graphics.origin()

	await_error_exit(error_message(message, trace))
end

return true
