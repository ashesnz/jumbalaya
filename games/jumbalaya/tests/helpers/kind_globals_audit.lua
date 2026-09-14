--[[ tests/helpers/kind_globals_audit.lua - Kind / legacy _G install boundaries ]]

local M = {}

local ENGINE_ALLOW = {
	["packages/jumbalaya-engine/globals.lua"] = true,
}

local WORD_GAME_ALLOW = {
	["word_game/ui/effects/easing.lua"] = true,
}

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
		paths.repo_root,
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

local function rel_path(abs, root_prefix)
	local paths = require("bootstrap_paths").resolve()
	local prefix = paths.repo_root .. "/"
	if abs:sub(1, #prefix) == prefix then
		return abs:sub(#prefix + 1)
	end
	return abs
end

local function has_global_assign(content)
	return content:find("_G%.%w+%s*=") ~= nil
end

function M.word_game_global_assignments()
	local violations = {}
	for _, abs in ipairs(list_lua_files("games/jumbalaya/word_game")) do
		local rel = rel_path(abs)
		if WORD_GAME_ALLOW[rel] then goto continue end
		local content = read_file(abs)
		if content and has_global_assign(content) then
			violations[#violations + 1] = rel
		end
		::continue::
	end
	table.sort(violations)
	return violations
end

function M.engine_kind_global_assignments()
	local violations = {}
	for _, abs in ipairs(list_lua_files("packages/jumbalaya-engine")) do
		local rel = rel_path(abs)
		if ENGINE_ALLOW[rel] then goto continue end
		local content = read_file(abs)
		if content and has_global_assign(content)
			and not content:find("function%s+M%.install")
			and not content:find("install_globals") then
			violations[#violations + 1] = rel
		end
		::continue::
	end
	table.sort(violations)
	return violations
end

return M
