--[[ tests/helpers/glue_hygiene_audit.lua - Phase 10a glue hygiene static scans ]]

local M = {}

local PENDING_LAYOUT_ALLOWLIST = {
	["word_game/model/layout/request.lua"] = true,
	["word_game/model/run/scope.lua"] = true,
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

function M.model_pending_layout_violations()
	local violations = {}
	for _, abs in ipairs(list_lua_files("word_game/model")) do
		local rel = rel_path(abs)
		if not PENDING_LAYOUT_ALLOWLIST[rel] then
			local text = read_file(abs)
			if text and text:find("pending_layout", 1, true) then
				violations[#violations + 1] = rel
			end
		end
	end
	return violations
end

function M.model_ui_boundary_violations()
	local violations = {}
	for _, abs in ipairs(list_lua_files("word_game/model")) do
		local rel = rel_path(abs)
		local text = read_file(abs)
		if text and text:find("WORD_GAME_UI", 1, true) then
			violations[#violations + 1] = rel .. " (WORD_GAME_UI)"
		elseif text and text:find("Funcs.dispatch", 1, true) then
			violations[#violations + 1] = rel .. " (Funcs.dispatch)"
		end
	end
	return violations
end

return M
