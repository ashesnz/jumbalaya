--[[ tests/helpers/facade_boundary_audit.lua
     Static audit: cross-package imports must use facades, not deep paths.
]]

local M = {}

local REQUIRE_PATTERNS = {
	'require%("word_game%.model%.([^"]+)"%)',
	"require%('word_game%.model%.([^']+)'%)",
	'require%("word_game%.ui%.([^"]+)"%)',
	"require%('word_game%.ui%.([^']+)'%)",
}

local function list_lua_files(subdirs)
	local files = {}
	local paths = require("bootstrap_paths").resolve()
	for _, subdir in ipairs(subdirs) do
		local abs = paths.game_root .. "/" .. subdir
		local handle = io.popen(string.format('find %s -name "*.lua" -type f 2>/dev/null', abs))
		if handle then
			for line in handle:lines() do
				files[#files + 1] = line
			end
			handle:close()
		end
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

local APP_WIRING = {
	["app/callbacks/overlays/init.lua"] = true,
}

local function is_allowed_app_path(rel)
	return rel:sub(1, #"app/bootstrap/") == "app/bootstrap/" or APP_WIRING[rel] == true
end

--- Deep word_game.* requires in app/ (outside bootstrap) and devtools/.
function M.shell_boundary_violations()
	local violations = {}
	for _, path in ipairs(list_lua_files({ "app", "devtools" })) do
		local rel = rel_path(path)
		if not is_allowed_app_path(rel) then
			local file = io.open(path, "r")
			if file then
				local content = file:read("*a")
				file:close()
				for _, pattern in ipairs(REQUIRE_PATTERNS) do
					for mod in content:gmatch(pattern) do
						violations[#violations + 1] = rel .. " -> word_game." .. mod
					end
				end
			end
		end
	end
	table.sort(violations)
	return violations
end

local function is_facade_module(rel)
	return rel:sub(1, #"word_game/ui/facade/") == "word_game/ui/facade/"
end

--- Deep word_game.model.* requires in word_game/ui outside ui/facade/.
function M.ui_model_boundary_violations()
	local violations = {}
	for _, path in ipairs(list_lua_files({ "word_game/ui" })) do
		local rel = rel_path(path)
		if not is_facade_module(rel) then
			local file = io.open(path, "r")
			if file then
				local content = file:read("*a")
				file:close()
				for mod in content:gmatch('require%("word_game%.model%.([^"]+)"%)') do
					violations[#violations + 1] = rel .. " -> word_game.model." .. mod
				end
				for mod in content:gmatch("require%('word_game%.model%.([^']+)'%)") do
					violations[#violations + 1] = rel .. " -> word_game.model." .. mod
				end
			end
		end
	end
	table.sort(violations)
	return violations
end

local UI_IMPORT_PATTERNS = {
	'require%("word_game%.ui%.([^"]+)"%)',
	"require%('word_game%.ui%.([^']+)'%)",
}

--- word_game/model/ must not import word_game/ui/ (presentation via Presentation.emit).
function M.model_ui_boundary_violations()
	local violations = {}
	for _, path in ipairs(list_lua_files({ "word_game/model" })) do
		local rel = rel_path(path)
		local file = io.open(path, "r")
		if file then
			local content = file:read("*a")
			file:close()
			for _, pattern in ipairs(UI_IMPORT_PATTERNS) do
				for mod in content:gmatch(pattern) do
					violations[#violations + 1] = rel .. " -> word_game.ui." .. mod
				end
			end
		end
	end
	table.sort(violations)
	return violations
end

return M
