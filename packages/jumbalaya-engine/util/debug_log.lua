--[[
	jumbalaya-engine/util/debug_log.lua - Temporary sidebar diagnostic logging.
	Writes to console, LÖVE save directory, and Desktop (macOS) so the user
	can easily find the log even when the working directory is unclear.
]]

local M = {}

local function desktop_path()
	local home = os.getenv("HOME") or os.getenv("USERPROFILE")
	if not home then return nil end
	local os_name = (love and love.system and love.system.getOS and love.system.getOS()) or ""
	if os_name == "OS X" then
		return home .. "/Desktop/sidebar_debug.log"
	end
	return nil
end

local function save_dir_path()
	if love and love.filesystem and love.filesystem.getSaveDirectory then
		local dir = love.filesystem.getSaveDirectory()
		if dir then
			return dir .. "/sidebar_debug.log"
		end
	end
	return nil
end

function M.log(msg)
	local timestamp = os.date("%H:%M:%S")
	local line = timestamp .. " " .. tostring(msg)
	print("[SIDEBAR_DBG] " .. line)

	-- Try LÖVE save directory first (most reliable in LÖVE).
	if love and love.filesystem and love.filesystem.append then
		local ok, err = pcall(love.filesystem.append, "sidebar_debug.log", line .. "\n")
		if ok then return end
		print("[SIDEBAR_DBG] save-dir append failed: " .. tostring(err))
	end

	-- Try an absolute Desktop path on macOS.
	local desktop = desktop_path()
	if desktop then
		local f = io.open(desktop, "a")
		if f then
			f:write(line .. "\n")
			f:close()
			return
		end
	end

	-- Fallback to process working directory.
	local f = io.open("sidebar_debug.log", "a")
	if f then
		f:write(line .. "\n")
		f:close()
	end
end

function M.print_locations()
	print("[SIDEBAR_DBG] Log locations:")
	if love and love.filesystem and love.filesystem.getSaveDirectory then
		print("[SIDEBAR_DBG]   save dir: " .. tostring(love.filesystem.getSaveDirectory()) .. "/sidebar_debug.log")
	end
	local desktop = desktop_path()
	if desktop then
		print("[SIDEBAR_DBG]   desktop:  " .. desktop)
	end
	print("[SIDEBAR_DBG]   cwd:      ./sidebar_debug.log")
end

return M