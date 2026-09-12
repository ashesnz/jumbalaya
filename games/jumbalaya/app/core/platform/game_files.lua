--[[ app/core/platform/game_files.lua - Read game data files via Love FS or disk fallback ]]

local BootstrapPaths = require("bootstrap_paths")

local M = {}

--- Mount games/jumbalaya when Love source is the repo root (`love .`).
function M.ensure_mounted()
	if not (love and love.filesystem and love.filesystem.mount) then
		return
	end
	local paths = BootstrapPaths.resolve()
	if paths.game_root == paths.source then
		return
	end
	love.filesystem.mount("/", paths.game_root, true)
end

---@param rel_path string Path relative to games/jumbalaya (e.g. localization/en-us.lua)
---@return string|nil
function M.read(rel_path)
	if love.filesystem and love.filesystem.getInfo(rel_path) then
		return love.filesystem.read(rel_path)
	end
	local paths = BootstrapPaths.resolve()
	local abs = paths.game_root .. "/" .. rel_path
	local file = io.open(abs, "r")
	if not file then
		return nil
	end
	local content = file:read("*a")
	file:close()
	return content
end

---@param rel_path string
---@return boolean
function M.exists(rel_path)
	if love.filesystem and love.filesystem.getInfo(rel_path) then
		return true
	end
	local paths = BootstrapPaths.resolve()
	return io.open(paths.game_root .. "/" .. rel_path, "r") ~= nil
end

return M
