--[[ tests/helpers/store_state_audit.lua
     Static audit: run-state keys must be declared in types/store.lua.
]]

local M = {}

local CATALOG_CLASSES = {
	"GameRunState",
	"GameStoreState",
	"WordRound",
	"JumbleState",
	"RunState",
	"PileState",
}

local SCAN_ROOTS = { "app", "word_game", "packages/jumbalaya_core/store" }
local SKIP_PREFIXES = { "tests/", "devtools/" }

local function should_scan(path)
	for _, prefix in ipairs(SKIP_PREFIXES) do
		if path:find("/" .. prefix, 1, true) or path:sub(-#prefix) == prefix then
			return false
		end
	end
	return true
end

local function list_lua_files()
	local files = {}
	local paths = require("bootstrap_paths").resolve()
	for _, root in ipairs(SCAN_ROOTS) do
		local abs = paths.game_root .. "/" .. root
		if root:match("^packages/") then
			abs = paths.repo_root .. "/" .. root
		end
		local handle = io.popen(string.format('find %s -name "*.lua" -type f 2>/dev/null', abs))
		if handle then
			for line in handle:lines() do
				if should_scan(line) then
					files[#files + 1] = line
				end
			end
			handle:close()
		end
	end
	table.sort(files)
	return files
end

local function read_file(path)
	local file = io.open(path, "r")
	if not file then return nil end
	local contents = file:read("*a")
	file:close()
	return contents
end

--- Parse @field entries from types/store.lua.
function M.load_catalog()
	local paths = require("bootstrap_paths").resolve()
	local content = read_file(paths.game_root .. "/types/store.lua") or ""
	local catalog = {}
	for _, class in ipairs(CATALOG_CLASSES) do
		catalog[class] = {}
	end

	local current = nil
	for line in content:gmatch("[^\n]+") do
		local class = line:match("^---@class (%S+)")
		if class and catalog[class] then
			current = class
		end
		local field = line:match("^---@field ([%w_]+)")
		if field and current and field ~= "[string]" then
			catalog[current][field] = true
		end
	end
	return catalog
end

function M.run_state_fields(catalog)
	local fields = {}
	for _, class in ipairs({ "GameRunState", "GameStoreState", "RunState" }) do
		for name in pairs(catalog[class] or {}) do
			fields[name] = true
		end
	end
	return fields
end

local function extract_patch_keys(content)
	local keys = {}
	local pos = 1
	while true do
		local start = content:find("game_access", pos, true)
		if not start then break end
		local patch_start = content:find(".patch({", start, true)
		if not patch_start or patch_start > start + 32 then
			pos = start + 1
		else
		local i = patch_start + #".patch({"
		local depth = 1
		while i <= #content and depth > 0 do
			local ch = content:sub(i, i)
			if ch == "{" then
				depth = depth + 1
			elseif ch == "}" then
				depth = depth - 1
			end
			i = i + 1
		end
		local block = content:sub(patch_start + #".patch({", i - 2)
		for line in block:gmatch("[^\n]+") do
			local key = line:match("^%s*([%w_]+)%s*=")
			if key then
				keys[key] = true
			end
		end
		pos = i
		end
	end
	return keys
end

local function extract_table_keys(block)
	local keys = {}
	local depth = 0
	for line in block:gmatch("[^\n]+") do
		local trimmed = line:match("^%s*(.*)$")
		if depth == 0 then
			local key = trimmed:match("^([%w_]+)%s*=")
			if key then
				keys[key] = true
			end
		end
		for _ in trimmed:gmatch("{") do
			depth = depth + 1
		end
		for _ in trimmed:gmatch("}") do
			depth = depth - 1
		end
	end
	return keys
end

local function extract_braced_table(content, marker)
	local start = content:find(marker, 1, true)
	if not start then return {} end
	local open = content:find("{", start, true)
	if not open then return {} end
	local depth = 1
	local i = open + 1
	while i <= #content and depth > 0 do
		local ch = content:sub(i, i)
		if ch == "{" then
			depth = depth + 1
		elseif ch == "}" then
			depth = depth - 1
		end
		i = i + 1
	end
	return extract_table_keys(content:sub(open + 1, i - 2))
end

local function extract_reducer_assignments(content)
	local top = {}
	local run_state = {}
	for key in content:gmatch("state%.([%w_]+)%s*=") do
		top[key] = true
	end
	for key in content:gmatch("state%.run_state%.([%w_]+)%s*=") do
		run_state[key] = true
	end
	return top, run_state
end

local function extract_default_state_keys()
	local paths = require("bootstrap_paths").resolve()
	local content = read_file(paths.repo_root .. "/packages/jumbalaya_core/store/default_state.lua") or ""
	return extract_braced_table(content, "function M.new(overrides)")
end

local function extract_busy_flags()
	local paths = require("bootstrap_paths").resolve()
	local content = read_file(paths.game_root .. "/word_game/model/run/busy.lua") or ""
	local keys = {}
	for flag in content:gmatch('"([%w_]+)"') do
		if flag:match("_busy$") then
			keys[flag] = true
		end
	end
	return keys
end

--- Keys written in source but not declared on GameRunState / GameStoreState.
function M.undeclared_run_state_keys()
	local catalog = M.load_catalog()
	local declared = M.run_state_fields(catalog)
	local used = {}

	for _, path in ipairs(list_lua_files()) do
		local content = read_file(path)
		if content then
			for key in pairs(extract_patch_keys(content)) do
				used[key] = used[key] or path
			end
			if path:find("/store/reducers/", 1, true) then
				local top, run_state = extract_reducer_assignments(content)
				for key in pairs(top) do
					used[key] = used[key] or path
				end
				for key in pairs(run_state) do
					used[key] = used[key] or path
				end
			end
		end
	end

	for key in pairs(extract_default_state_keys()) do
		used[key] = used[key] or "packages/jumbalaya_core/store/default_state.lua"
	end
	for key in pairs(extract_busy_flags()) do
		used[key] = used[key] or "word_game/model/run/busy.lua"
	end

	local nested_ok = {
		word_round = true,
		run_state = true,
		piles = true,
		state = true,
	}
	local undeclared = {}
	for key, path in pairs(used) do
		if not declared[key] and not nested_ok[key] then
			undeclared[#undeclared + 1] = key .. " (" .. path .. ")"
		end
	end
	table.sort(undeclared)
	return undeclared
end

return M
