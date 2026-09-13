--[[ app/platform/game_files.lua - Read game data files via Love FS or disk fallback ]]

local BootstrapPaths = require("bootstrap_paths")

local M = {}

function M.ensure_mounted()
	if not (love and love.filesystem and love.filesystem.mount) then
		return
	end
	local paths = BootstrapPaths.resolve()
	if paths.game_root == paths.source then
		return
	end
	love.filesystem.mount(paths.game_root, "/", true)
end

function M.absolute_path(rel_path)
	return M.game_paths().game_root .. "/" .. rel_path
end

function M.game_paths()
	return BootstrapPaths.resolve()
end

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

function M.exists(rel_path)
	if love.filesystem and love.filesystem.getInfo(rel_path) then
		return true
	end
	local file = io.open(M.absolute_path(rel_path), "r")
	if file then
		file:close()
		return true
	end
	return false
end

--- Load through love FS when mounted, otherwise from disk via FileData.
function M.load_image(rel_path, opts)
	M.ensure_mounted()
	opts = opts or {}
	if love.filesystem and love.filesystem.getInfo(rel_path) then
		return love.graphics.newImage(rel_path, opts)
	end
	local file = io.open(M.absolute_path(rel_path), "rb")
	if not file then
		return nil
	end
	local bytes = file:read("*a")
	file:close()
	if not bytes or bytes == "" then
		return nil
	end
	local leaf = rel_path:match("[^/\\]+$") or "asset.png"
	return love.graphics.newImage(love.filesystem.newFileData(bytes, leaf), opts)
end

return M
