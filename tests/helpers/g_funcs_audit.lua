--[[ tests/helpers/g_funcs_audit.lua
     Static audit for G.FUNCS catalog compliance (engine migration Phase 0).
]]

local M = {}

local SCAN_ROOTS = { "app", "word_game" }
local SKIP_PATH_PREFIXES = { "devtools/" }

local function should_scan(path)
	for _, prefix in ipairs(SKIP_PATH_PREFIXES) do
		if path:sub(1, #prefix) == prefix then
			return false
		end
	end
	return true
end

local function list_lua_files()
	local files = {}
	local handle = io.popen('find app word_game -name "*.lua" -type f 2>/dev/null')
	if not handle then
		return files
	end
	for line in handle:lines() do
		if should_scan(line) then
			files[#files + 1] = line
		end
	end
	handle:close()
	table.sort(files)
	return files
end

--- Parse GameFuncName entries from types/g_funcs.lua.
function M.load_catalog()
	local file = io.open("types/g_funcs.lua", "r")
	if not file then
		return {}
	end
	local contents = file:read("*a")
	file:close()

	local catalog = {}
	for name in contents:gmatch('---%| "([%w_]+)"') do
		catalog[name] = true
	end
	return catalog
end

--- Collect G.FUNCS names assigned in production source.
function M.scan_registrations()
	local names = {}
	for _, path in ipairs(list_lua_files()) do
		local file = io.open(path, "r")
		if file then
		local contents = file:read("*a")
		file:close()

		for name in contents:gmatch("G%.FUNCS%.([%w_]+)%s*=") do
			names[name] = names[name] or path
		end
		for name in contents:gmatch("function%s+G%.FUNCS%.([%w_]+)%s*%(") do
			names[name] = names[name] or path
		end
		for name in contents:gmatch("runtime%(%)%.FUNCS%.([%w_]+)%s*=") do
			names[name] = names[name] or path
		end
		for name in contents:gmatch("function%s+runtime%(%)%.FUNCS%.([%w_]+)%s*%(") do
			names[name] = names[name] or path
		end
		for name in contents:gmatch('Funcs%.register%("([%w_]+)"') do
			names[name] = names[name] or path
		end
		for name in contents:gmatch("g%(%)%.FUNCS%.([%w_]+)%s*=") do
			names[name] = names[name] or path
		end
		end
	end
	return names
end

--- Registrations in source that are not listed in types/g_funcs.lua.
function M.unlisted_registrations()
	local catalog = M.load_catalog()
	local registered = M.scan_registrations()
	local unlisted = {}
	for name, path in pairs(registered) do
		if not catalog[name] then
			unlisted[#unlisted + 1] = name .. " (" .. path .. ")"
		end
	end
	table.sort(unlisted)
	return unlisted
end

--- Catalog entries with no static registration in app/ or word_game/.
function M.missing_implementations()
	local catalog = M.load_catalog()
	local registered = M.scan_registrations()
	local missing = {}
	for name in pairs(catalog) do
		if not registered[name] then
			missing[#missing + 1] = name
		end
	end
	table.sort(missing)
	return missing
end

return M
