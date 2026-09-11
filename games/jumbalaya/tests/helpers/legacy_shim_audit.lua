--[[ tests/helpers/legacy_shim_audit.lua
     Detect one-line `return require(...)` proxy files and stale shim paths.
]]

local M = {}

--- Deleted proxies — must not reappear.
local FORBIDDEN_PROXY_FILES = {
	"word_game/config/gameplay/round.lua",
	"word_game/config/gameplay/economy.lua",
	"word_game/ui/effects/timeline_scheduler.lua",
	"word_game/ui/views/ui_view_host.lua",
	"word_game/ui/util/number_format.lua",
	"word_game/ui/util/roll.lua",
}

local STALE_REQUIRE_PATTERNS = {
	"jumbalaya%-engine%.retained_ui",
	"jumbalaya%-engine%.view_host",
	"word_game%.config%.gameplay%.round",
	"word_game%.config%.gameplay%.economy",
	"word_game%.ui%.effects%.timeline_scheduler",
	"word_game%.ui%.views%.ui_view_host",
	"word_game%.ui%.util%.number_format",
	"word_game%.ui%.util%.roll",
}

--- Bootstrap entry points allowed to delegate to jumbalaya-engine at load time.
local PROXY_ALLOWLIST = {
	["app/bootstrap/engine_boot.lua"] = true,
}

--- Trees that must not contain new one-line return-require proxies.
local NO_PROXY_PREFIXES = {
	"word_game/",
}

local function read_file(path)
	local file = io.open(path, "r")
	if not file then return nil end
	local content = file:read("*a")
	file:close()
	return content
end

local function list_lua_files()
	local files = {}
	local paths = require("bootstrap_paths").resolve()
	local handle = io.popen(string.format(
		'find %s/app %s/word_game %s/devtools -name "*.lua" -type f 2>/dev/null',
		paths.game_root,
		paths.game_root,
		paths.game_root
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

--- True when the file body is only `return require("module")` (optional `.method(...)`).
function M.is_return_require_proxy(content)
	local body = strip_comments(content or "")
	if body == "" then
		return false
	end
	if body:find("\n") then
		return false
	end
	return body:match("^return%s+require%s*%(.+%)%s*$") ~= nil
		or body:match("^return%s+require%s*%(.+%)%..+%(.*%)%s*$") ~= nil
end

--- True when the file only side-effect-loads a module and returns true (global shim).
function M.is_side_effect_shim(content)
	local body = strip_comments(content or "")
	if body == "" or body:match("return%s+require") then
		return false
	end
	if not body:match("^require%s") then
		return false
	end
	local non_require = {}
	for line in body:gmatch("[^\n]+") do
		if not line:match("^require%s") then
			non_require[#non_require + 1] = line
		end
	end
	return #non_require == 1 and non_require[1]:match("^return%s+true%s*$") ~= nil
end

--- All one-line return-require proxy files under app/ and word_game/.
function M.scan_return_require_proxies()
	local proxies = {}
	for _, abs in ipairs(list_lua_files()) do
		local rel = rel_path(abs)
		local content = read_file(abs)
		if content and M.is_return_require_proxy(content) then
			proxies[#proxies + 1] = rel
		end
	end
	table.sort(proxies)
	return proxies
end

--- Proxies in word_game/ (and other NO_PROXY_PREFIXES) outside the allowlist.
function M.unauthorized_proxy_files()
	local unauthorized = {}
	for _, rel in ipairs(M.scan_return_require_proxies()) do
		if not PROXY_ALLOWLIST[rel] then
			for _, prefix in ipairs(NO_PROXY_PREFIXES) do
				if rel:sub(1, #prefix) == prefix then
					unauthorized[#unauthorized + 1] = rel
					break
				end
			end
		end
	end
	table.sort(unauthorized)
	return unauthorized
end

--- Side-effect-only shim files (require + return true) under word_game/.
function M.side_effect_shim_files()
	local shims = {}
	for _, abs in ipairs(list_lua_files()) do
		local rel = rel_path(abs)
		if rel:sub(1, #"word_game/") == "word_game/" then
			local content = read_file(abs)
			if content and M.is_side_effect_shim(content) then
				shims[#shims + 1] = rel
			end
		end
	end
	table.sort(shims)
	return shims
end

--- Proxy shim files that should not exist after Phase 10 purge.
function M.forbidden_proxy_files_present()
	local paths = require("bootstrap_paths").resolve()
	local present = {}
	for _, rel in ipairs(FORBIDDEN_PROXY_FILES) do
		local abs = paths.game_root .. "/" .. rel
		if read_file(abs) then
			present[#present + 1] = rel
		end
	end
	table.sort(present)
	return present
end

local function grep_stale(pattern)
	local paths = require("bootstrap_paths").resolve()
	local stale = {}
	local handle = io.popen(string.format(
		'grep -rl "%s" %s/app %s/word_game %s/tests %s/devtools 2>/dev/null || true',
		pattern,
		paths.game_root,
		paths.game_root,
		paths.game_root,
		paths.game_root
	))
	if handle then
		for line in handle:lines() do
			local rel = line:gsub(paths.game_root .. "/", "")
			if not rel:match("legacy_shim_audit%.lua$") then
				stale[#stale + 1] = rel
			end
		end
		handle:close()
	end
	return stale
end

--- require() paths that still point at removed proxy modules.
function M.stale_proxy_requires()
	local stale = {}
	local seen = {}
	for _, pattern in ipairs(STALE_REQUIRE_PATTERNS) do
		for _, rel in ipairs(grep_stale(pattern)) do
			if not seen[rel] then
				seen[rel] = true
				stale[#stale + 1] = rel
			end
		end
	end
	table.sort(stale)
	return stale
end

return M
