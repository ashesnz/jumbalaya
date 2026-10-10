--[[
	jumbalaya-engine/persistence/save_paths.lua - Jumbalaya save filenames.

	Older saves used `.acs` (compressed Lua). New saves use `.jmb`.
	Readers accept either extension; writers always use `.jmb`.
]]

local M = {
	EXT = ".jmb",
	LEGACY_EXT = ".acs",
}

---@param relative string e.g. "settings" or "1/profile" (no extension)
function M.read_path_for(relative)
	local modern = relative .. M.EXT
	if love.filesystem.getInfo(modern) then
		return modern
	end
	local legacy = relative .. M.LEGACY_EXT
	if love.filesystem.getInfo(legacy) then
		return legacy
	end
	return modern
end

---@param relative string path without extension
function M.write_path_for(relative)
	return relative .. M.EXT
end

function M.legacy_path_for(relative)
	return relative .. M.LEGACY_EXT
end

function M.exists(relative)
	return love.filesystem.getInfo(M.read_path_for(relative)) ~= nil
end

M.settings = "settings"
M.metrics = "metrics"
M.profile = "profile"
M.save = "save"
M.meta = "meta"

return M
