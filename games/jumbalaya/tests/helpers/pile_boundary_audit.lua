--[[ tests/helpers/pile_boundary_audit.lua - Card / CardPile vs store boundary scans ]]

local M = {}

local MODEL_FORBIDDEN = {
	"word_game%.ui%.cardarea",
	"word_game/ui/cardarea",
}

local CARDAREA_FORBIDDEN = {
	"word_game%.model%.jumble_play",
	"word_game%.model%.trade",
	"jumbalaya_core%.rules",
	"jumbalaya_core%.jumble",
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

local function strip_comments(text)
	local lines = {}
	for line in text:gmatch("[^\n]+") do
		local code = line:match("^(.-)%-%-") or line
		code = code:match("^%s*(.-)%s*$") or ""
		if code ~= "" then
			lines[#lines + 1] = code
		end
	end
	return table.concat(lines, "\n")
end

local function scan_forbidden(root, patterns)
	local violations = {}
	for _, abs in ipairs(list_lua_files(root)) do
		local content = read_file(abs)
		if content then
			local body = strip_comments(content)
			for _, pattern in ipairs(patterns) do
				if body:find(pattern) then
					violations[#violations + 1] = rel_path(abs) .. " (" .. pattern .. ")"
					break
				end
			end
		end
	end
	table.sort(violations)
	return violations
end

function M.model_cardarea_imports()
	return scan_forbidden("word_game/model", MODEL_FORBIDDEN)
end

function M.cardarea_gameplay_imports()
	return scan_forbidden("word_game/ui/cardarea", CARDAREA_FORBIDDEN)
end

return M
