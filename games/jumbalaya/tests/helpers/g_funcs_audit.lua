--[[ tests/helpers/g_funcs_audit.lua
     Static audit for UIBox callback catalog compliance (engine migration).
]]

local M = {}

local SKIP_PATH_PREFIXES = { "devtools/" }

local GAMEPAD_BUTTONS = {
	x = true,
	y = true,
	a = true,
	b = true,
	leftshoulder = true,
	rightshoulder = true,
}

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
	local paths = require("bootstrap_paths").resolve()
	local find_cmd = string.format(
		'find %s/app %s/word_game -name "*.lua" -type f 2>/dev/null',
		paths.game_root,
		paths.game_root
	)
	local handle = io.popen(find_cmd)
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

--- Parse GameFuncName entries from types/funcs.lua.
function M.load_catalog()
	local paths = require("bootstrap_paths").resolve()
	local file = io.open(paths.game_root .. "/types/funcs.lua", "r")
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

local function is_callback_button(name)
	if not name or name == "" then
		return false
	end
	if GAMEPAD_BUTTONS[name] then
		return false
	end
	if #name <= 2 then
		return false
	end
	return name:match("^[%a][%w_]*$") ~= nil
end

local function collect_callback_names(content, names)
	for key in content:gmatch("func%s*=%s*['\"]([%w_]+)['\"]") do
		names[key] = true
	end
	for key in content:gmatch("back_func%s*=%s*['\"]([%w_]+)['\"]") do
		names[key] = true
	end
	for key in content:gmatch("button%s*=%s*['\"]([%w_]+)['\"]") do
		if is_callback_button(key) then
			names[key] = true
		end
	end
	for key in content:gmatch("%.button%s*=%s*['\"]([%w_]+)['\"]") do
		if is_callback_button(key) then
			names[key] = true
		end
	end
	for key in content:gmatch('Funcs%.dispatch%("([%w_]+)"') do
		names[key] = true
	end
	for key in content:gmatch("Funcs%.dispatch%('([%w_]+)'") do
		names[key] = true
	end
end

--- UIBox bindings and Funcs.dispatch targets in app/ and word_game/.
function M.scan_ui_bindings()
	local names = {}
	for _, path in ipairs(list_lua_files()) do
		local file = io.open(path, "r")
		if file then
			local contents = file:read("*a")
			file:close()
			collect_callback_names(contents, names)
		end
	end
	return names
end

--- Collect callback names registered in production source.
function M.scan_registrations()
	local names = {}
	for _, path in ipairs(list_lua_files()) do
		local file = io.open(path, "r")
		if file then
			local contents = file:read("*a")
			file:close()

			for name in contents:gmatch('Funcs%.register%("([%w_]+)"') do
				names[name] = names[name] or path
			end
		end
	end
	return names
end

--- Registrations in source that are not listed in types/funcs.lua.
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

--- UIBox bindings / dispatches that are not listed in types/funcs.lua.
function M.unlisted_ui_bindings()
	local catalog = M.load_catalog()
	local bindings = M.scan_ui_bindings()
	local unlisted = {}
	for name in pairs(bindings) do
		if not catalog[name] then
			unlisted[#unlisted + 1] = name
		end
	end
	table.sort(unlisted)
	return unlisted
end

--- Cataloged callbacks referenced in UI but never registered.
function M.unregistered_ui_bindings()
	local catalog = M.load_catalog()
	local bindings = M.scan_ui_bindings()
	local registered = M.scan_registrations()
	local missing = {}
	for name in pairs(bindings) do
		if catalog[name] and not registered[name] then
			missing[#missing + 1] = name
		end
	end
	table.sort(missing)
	return missing
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
