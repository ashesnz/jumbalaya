--[[ tests/helpers/presentation_catalog_audit.lua
     Static audit for Presentation bus catalog compliance.
]]

local M = {}

local HANDLER_ROOT = "word_game/ui/presentation/handlers/"
local SKIP_PATH_PREFIXES = { "devtools/", "tests/" }
local EMIT_SKIP_SUBPATH = "/ui/presentation/handlers/"

local function should_scan(path)
	for _, prefix in ipairs(SKIP_PATH_PREFIXES) do
		if path:sub(1, #prefix) == prefix or path:find("/" .. prefix, 1, true) then
			return false
		end
	end
	return true
end

local function should_scan_emit(path)
	if not should_scan(path) then
		return false
	end
	return not path:find(EMIT_SKIP_SUBPATH, 1, true)
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

local function read_file(path)
	local file = io.open(path, "r")
	if not file then
		return nil
	end
	local contents = file:read("*a")
	file:close()
	return contents
end

--- Parse PresentationEventName entries from types/presentation_events.lua.
function M.load_catalog()
	local paths = require("bootstrap_paths").resolve()
	local contents = read_file(paths.game_root .. "/types/presentation_events.lua")
	if not contents then
		return {}
	end

	local catalog = {}
	for name in contents:gmatch('---%| "([^"]+)"') do
		catalog[name] = true
	end
	return catalog
end

local function collect_emit_names(content, names, path)
	for name in content:gmatch('Presentation%.emit%("([^"]+)"') do
		names[name] = names[name] or path
	end
	for name in content:gmatch("Presentation%.emit%('([^']+)'") do
		names[name] = names[name] or path
	end
	for name in content:gmatch('PresentationBus%.emit%("([^"]+)"') do
		names[name] = names[name] or path
	end
	for name in content:gmatch("PresentationBus%.emit%('([^']+)'") do
		names[name] = names[name] or path
	end
	for name in content:gmatch('facade%.presentation%(%)%s*%.emit%("([^"]+)"') do
		names[name] = names[name] or path
	end
	for name in content:gmatch("facade%.presentation%(%)%s*%.emit%('([^']+)'") do
		names[name] = names[name] or path
	end
end

local function collect_handler_names(content, names, path)
	for name in content:gmatch('Presentation%.on%("([^"]+)"') do
		names[name] = names[name] or path
	end
	for name in content:gmatch("Presentation%.on%('([^']+)'") do
		names[name] = names[name] or path
	end
end

--- Presentation.on registrations in ui/presentation/handlers/.
function M.scan_handlers()
	local names = {}
	local paths = require("bootstrap_paths").resolve()
	local abs_root = paths.game_root .. "/" .. HANDLER_ROOT
	local handle = io.popen(string.format('find %s -name "*.lua" -type f 2>/dev/null', abs_root))
	if not handle then
		return names
	end
	for line in handle:lines() do
		local contents = read_file(line)
		if contents then
			collect_handler_names(contents, names, line)
		end
	end
	handle:close()
	return names
end

--- Presentation.emit sites outside handler fan-out modules.
function M.scan_external_emits()
	local names = {}
	for _, path in ipairs(list_lua_files()) do
		if should_scan_emit(path) then
			local contents = read_file(path)
			if contents then
				collect_emit_names(contents, names, path)
			end
		end
	end
	return names
end

--- Handlers not listed in types/presentation_events.lua.
function M.unlisted_handlers()
	local catalog = M.load_catalog()
	local handlers = M.scan_handlers()
	local unlisted = {}
	for name, path in pairs(handlers) do
		if not catalog[name] then
			unlisted[#unlisted + 1] = name .. " (" .. path .. ")"
		end
	end
	table.sort(unlisted)
	return unlisted
end

--- Catalog entries with no Presentation.on handler.
function M.missing_handlers()
	local catalog = M.load_catalog()
	local handlers = M.scan_handlers()
	local missing = {}
	for name in pairs(catalog) do
		if not handlers[name] then
			missing[#missing + 1] = name
		end
	end
	table.sort(missing)
	return missing
end

--- External emit sites not listed in types/presentation_events.lua.
function M.unlisted_emits()
	local catalog = M.load_catalog()
	local emits = M.scan_external_emits()
	local unlisted = {}
	for name, path in pairs(emits) do
		if not catalog[name] then
			unlisted[#unlisted + 1] = name .. " (" .. path .. ")"
		end
	end
	table.sort(unlisted)
	return unlisted
end

return M
