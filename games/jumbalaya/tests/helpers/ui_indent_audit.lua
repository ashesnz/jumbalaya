--[[ tests/helpers/ui_indent_audit.lua - word_game/ui uses tabs for indentation ]]

local M = {}

local function read_file(path)
	local file = io.open(path, "r")
	if not file then return nil end
	local content = file:read("*a")
	file:close()
	return content
end

local function list_lua_files(root)
	local files = {}
	local paths = require("bootstrap_paths").resolve()
	local handle = io.popen(string.format(
		'find %s/%s -name "*.lua" -type f 2>/dev/null',
		paths.game_root,
		root
	))
	if handle then
		for line in handle:lines() do
			files[#files + 1] = line
		end
		handle:close()
	end
	table.sort(files)
	return files
end

local function rel_path(abs)
	local paths = require("bootstrap_paths").resolve()
	local prefix = paths.game_root .. "/"
	if abs:sub(1, #prefix) == prefix then
		return abs:sub(#prefix + 1)
	end
	return abs
end

--- Lines indented with leading spaces instead of tabs.
function M.space_indented_files()
	local violations = {}
	for _, abs in ipairs(list_lua_files("word_game/ui")) do
		local content = read_file(abs)
		if content then
			for line in content:gmatch("[^\n]+") do
				if line:match("^ ") and not line:match("^\t") then
					violations[#violations + 1] = rel_path(abs)
					break
				end
			end
		end
	end
	table.sort(violations)
	return violations
end

return M
