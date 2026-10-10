--[[ tests/helpers/uit_audit.lua
     Static freeze: new word_game/ui files must not author game().UI kind integers.
]]

local M = {}

local function strip_comment(line)
	local in_string = false
	local quote = nil
	local i = 1
	while i <= #line do
		local c = line:sub(i, i)
		if in_string then
			if c == "\\" then
				i = i + 2
			elseif c == quote then
				in_string = false
				quote = nil
				i = i + 1
			else
				i = i + 1
			end
		elseif c == "'" or c == '"' then
			in_string = true
			quote = c
			i = i + 1
		elseif c == "-" and line:sub(i + 1, i + 1) == "-" then
			return line:sub(1, i - 1)
		else
			i = i + 1
		end
	end
	return line
end

local function list_ui_lua()
	local files = {}
	local paths = require("bootstrap_paths").resolve()
	local find_cmd = string.format(
		'find %s/word_game/ui -name "*.lua" -type f 2>/dev/null',
		paths.game_root
	)
	local handle = io.popen(find_cmd)
	if not handle then
		return files
	end
	for line in handle:lines() do
		files[#files + 1] = line
	end
	handle:close()
	table.sort(files)
	return files
end

local function rel_path(path)
	local paths = require("bootstrap_paths").resolve()
	local prefix = paths.game_root .. "/"
	if path:sub(1, #prefix) == prefix then
		return path:sub(#prefix + 1)
	end
	return path
end

local function allowlist_set()
	local listed = require("tests.helpers.uit_allowlist")
	local set = {}
	for _, path in ipairs(listed) do
		set[path] = true
	end
	return set
end

--- Paths (relative to games/jumbalaya) that use n = game().UI.* outside the allowlist.
function M.violations()
	local allowed = allowlist_set()
	local found = {}
	for _, path in ipairs(list_ui_lua()) do
		local rel = rel_path(path)
		if not allowed[rel] then
			local file = io.open(path, "r")
			if file then
				local contents = file:read("*a")
				file:close()
				contents = contents:gsub("%-%-%[%[.-%]%]", "")
				local lineno = 0
				for line in (contents .. "\n"):gmatch("(.-)\n") do
					lineno = lineno + 1
					local code = strip_comment(line)
					local kind = code:find("%.UI%.(ROOT|ROW|COLUMN|TEXT|BOX|OBJECT|SLIDER|INPUT)%f[%W]")
					if kind and (code:find("n%s*=") or code:find("and .*UI%.") or code:find("or .*UI%.")) then
						found[#found + 1] = rel .. ":" .. lineno
					end
				end
			end
		end
	end
	table.sort(found)
	return found
end

--- Allowlist entries that no longer contain UIT nodes (should be dropped).
function M.stale_allowlist()
	local allowed = require("tests.helpers.uit_allowlist")
	local stale = {}
	local paths = require("bootstrap_paths").resolve()
	for _, rel in ipairs(allowed) do
		local file = io.open(paths.game_root .. "/" .. rel, "r")
		if not file then
			stale[#stale + 1] = rel .. " (missing)"
		else
			local contents = file:read("*a")
			file:close()
			if not contents:find("%.UI%.(ROOT|ROW|COLUMN|TEXT|BOX|OBJECT|SLIDER|INPUT)") then
				stale[#stale + 1] = rel
			end
		end
	end
	table.sort(stale)
	return stale
end

return M
