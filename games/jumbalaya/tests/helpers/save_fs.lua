--[[ tests/helpers/save_fs.lua - In-memory love.filesystem overlay for save I/O tests ]]

local M = {}

local files = {}
local real = {}

--- Route save read/write through an in-memory table so tests do not depend on
--- the OS Love2D save directory (which may be outside the workspace sandbox).
function M.install()
	if M._installed then return end
	M._installed = true

	real.write = love.filesystem.write
	real.read = love.filesystem.read
	real.getInfo = love.filesystem.getInfo
	real.remove = love.filesystem.remove

	function love.filesystem.write(path, data, size)
		files[path] = data
		return true, size
	end

	function love.filesystem.read(path)
		if files[path] ~= nil then
			return files[path]
		end
		return real.read(path)
	end

	function love.filesystem.getInfo(path, filtertype)
		if files[path] ~= nil then
			return { type = "file", size = #files[path] }
		end
		return real.getInfo(path, filtertype)
	end

	function love.filesystem.remove(path)
		files[path] = nil
		if real.remove then
			return real.remove(path)
		end
		return false
	end
end

function M.reset()
	for key in pairs(files) do
		files[key] = nil
	end
end

return M
