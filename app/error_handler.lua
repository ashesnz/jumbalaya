--[[
	Crash fallback UI and opt-in mail to support@jumbalaya.co.

	Unhandled errors always write error.log. If the player opted in to crash
	reports in Game settings, the handler opens a mailto: draft — nothing is
	POSTed to a remote collector.
]]

local SUPPORT_EMAIL = "support@jumbalaya.co"
local MAILTO_BODY_LIMIT = 1600

local M = {
	SUPPORT_EMAIL = SUPPORT_EMAIL,
}

local function encode_mailto(value)
	return tostring(value or "")
		:gsub("\r\n", "\n")
		:gsub("\n", "\r\n")
		:gsub("([^%w%-_%.~])", function(character)
			return string.format("%%%02X", string.byte(character))
		end)
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

local function report_body(message)
	local file, function_line, trace = relevant_trace(message)
	local version = (G and G.VERSION) or VERSION or "?"
	local body = "Jumbalaya crash report\n"
		.. "version: " .. tostring(version) .. "\n"
		.. "file: " .. tostring(file) .. "\n"
		.. "where: " .. tostring(function_line) .. "\n\n"
		.. tostring(message) .. "\n\n"
		.. tostring(trace)
	if #body > MAILTO_BODY_LIMIT then
		body = string.sub(body, 1, MAILTO_BODY_LIMIT) .. "\n…(truncated; full log is error.log in the LÖVE save folder)"
	end
	return body
end

function M.crash_mailto_url(message)
	local subject = "Jumbalaya crash (" .. tostring((G and G.VERSION) or VERSION or "?") .. ")"
	return "mailto:" .. SUPPORT_EMAIL
		.. "?subject=" .. encode_mailto(subject)
		.. "&body=" .. encode_mailto(report_body(message))
end

function M.crash_reports_opted_in()
	return G
		and G.SETTINGS
		and G.SETTINGS.crashreports
		and _RELEASE_MODE
		and G.F_CRASH_REPORTS
		and true
		or false
end

function M.open_crash_mail(message)
	local url = M.crash_mailto_url(message)
	if love.system and love.system.openURL then
		pcall(love.system.openURL, url)
	end
	return url
end

function M.player_error_message(message, trace)
	if not _RELEASE_MODE then
		return "Oops! Something went wrong:\n"
			.. message
			.. "\n\n"
			.. trace
			.. "\n\n---\nFull error also printed in Terminal and saved to error.log"
			.. "\nin your LÖVE save folder (see Terminal output for path)."
			.. "\nEmail " .. SUPPORT_EMAIL .. " if you want help."
	end

	if M.crash_reports_opted_in() then
		return "Oops! Something went wrong:\n"
			.. message
			.. "\n\nYour email app should open a draft to "
			.. SUPPORT_EMAIL
			.. " with useful info about what happened."
			.. "\nYou still choose whether to send it. A full log is in error.log"
			.. "\nin your LÖVE save folder. Turn Crash Reports Off in Game settings"
			.. " to stop opening a draft."
	end

	return "Oops! Something went wrong:\n"
		.. message
		.. "\n\nPlease email " .. SUPPORT_EMAIL
		.. " with error.log from your LÖVE save folder."
		.. "\nOr turn Crash Reports On in Game settings to open a mail draft next time."
end

local function ensure_error_window()
	if love.graphics.isCreated() and love.window.isOpen() then
		return true
	end

	local success, status = pcall(love.window.setMode, 800, 600)
	return success and status
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

	if M.crash_reports_opted_in() then
		M.open_crash_mail(message)
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

	await_error_exit(M.player_error_message(message, trace))
end

return M
