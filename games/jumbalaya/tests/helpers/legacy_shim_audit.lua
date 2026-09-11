--[[ tests/helpers/legacy_shim_audit.lua
     Reject one-line config re-export proxies under word_game/config/gameplay/.
]]

local M = {}

local FORBIDDEN_PROXY_FILES = {
	"word_game/config/gameplay/round.lua",
	"word_game/config/gameplay/economy.lua",
}

local function read_file(path)
	local file = io.open(path, "r")
	if not file then return nil end
	local content = file:read("*a")
	file:close()
	return content
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

--- require() paths that still point at removed gameplay config proxies.
function M.stale_config_requires()
	local paths = require("bootstrap_paths").resolve()
	local stale = {}
	local handle = io.popen(string.format(
		'grep -rl "word_game\\.config\\.gameplay\\.round\\|word_game\\.config\\.gameplay\\.economy" %s/app %s/word_game %s/tests %s/devtools 2>/dev/null || true',
		paths.game_root,
		paths.game_root,
		paths.game_root,
		paths.game_root
	))
	if handle then
		for line in handle:lines() do
			stale[#stale + 1] = line:gsub(paths.game_root .. "/", "")
		end
		handle:close()
	end
	table.sort(stale)
	return stale
end

return M
