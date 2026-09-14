--[[ tests/helpers/game_shell_audit.lua - Game shell field writes go through shell_access ]]

local M = {}

local ALLOW_ASSIGN = {
	["word_game/model/shell_access.lua"] = true,
	["word_game/model/game/run.lua"] = true,
	["word_game/model/game/init.lua"] = true,
	["word_game/model/game/globals.lua"] = true,
	["word_game/model/run/scope.lua"] = true,
}

--- Fields that must be written only via shell_access (not ad-hoc on game()/live_game()).
local OWNED_FIELDS = {
	letter_inventory = true,
	letter_card_id = true,
	sort_id = true,
	under_overlay = true,
	shared_shadow = true,
	last_materialized = true,
	main_menu_logo_applied_scale = true,
	focused_profile = true,
	table_shuffle_bar = true,
	hand_action_bar = true,
	table_shuffle_button = true,
	hand_play_button = true,
	PLAY_WORD_UI = true,
}

local ASSIGN_PATTERNS = {
	"live_game%(%).([%w_]+)%s*=",
	"game%(%).([%w_]+)%s*=",
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

function M.direct_shell_assignments()
	local violations = {}
	for _, abs in ipairs(list_lua_files("word_game")) do
		local rel = rel_path(abs)
		if ALLOW_ASSIGN[rel] then goto continue end
		local content = read_file(abs)
		if content then
			for _, pattern in ipairs(ASSIGN_PATTERNS) do
				for field in content:gmatch(pattern) do
					if OWNED_FIELDS[field] then
						violations[#violations + 1] = rel .. " -> " .. field
						break
					end
				end
			end
		end
		::continue::
	end
	table.sort(violations)
	return violations
end

return M
