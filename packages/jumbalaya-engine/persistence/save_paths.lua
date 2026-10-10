--[[
	jumbalaya-engine/persistence/save_paths.lua - Jumbalaya save filenames.

	Saves use `.jmb` (compressed Lua).
]]

local M = {
	EXT = ".jmb",
}

---@param relative string e.g. "settings" or "1/profile" (no extension)
function M.read_path_for(relative)
	return relative .. M.EXT
end

---@param relative string path without extension
function M.write_path_for(relative)
	return relative .. M.EXT
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
