--[[ tests/helpers/core_purity_audit.lua
     Static audit: jumbalaya_core must stay headless (no Love2D / game shell).
]]

local M = {}

local FORBIDDEN_REQUIRE_PREFIXES = {
	"app.",
	"word_game.",
	"jumbalaya-engine.",
	"jumbalaya_engine.",
}

local FORBIDDEN_TOKEN_PATTERNS = {
	{ pattern = "love%.", label = "love.* API" },
	{ pattern = "require%([\"']app%.", label = "app/ import" },
	{ pattern = "require%([\"']word_game%.", label = "word_game/ import" },
	{ pattern = "require%([\"']jumbalaya%-engine%.", label = "jumbalaya-engine import" },
	{ pattern = "WORD_GAME_UI", label = "WORD_GAME_UI global" },
	{ pattern = "WORD_GAME[^_]", label = "WORD_GAME global" },
	{ pattern = "_G%.G", label = "_G.G singleton" },
	{ pattern = "%f[%w]G%.GAME%f[%W]", label = "G.GAME access" },
}

local function list_core_files()
	local files = {}
	local paths = require("bootstrap_paths").resolve()
	local handle = io.popen(string.format(
		'find %s/packages/jumbalaya_core -name "*.lua" -type f 2>/dev/null',
		paths.repo_root
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

local function strip_comments(line)
	local code = line
	local comment = code:find("%-%-")
	if comment then
		code = code:sub(1, comment - 1)
	end
	return code
end

local function rel_path(abs)
	local paths = require("bootstrap_paths").resolve()
	local prefix = paths.repo_root .. "/packages/jumbalaya_core/"
	if abs:sub(1, #prefix) == prefix then
		return abs:sub(#prefix + 1)
	end
	return abs
end

--- Lines that violate headless / pure-core boundaries.
function M.violations()
	local hits = {}
	for _, path in ipairs(list_core_files()) do
		local file = io.open(path, "r")
		if file then
			local line_no = 0
			for line in file:lines() do
				line_no = line_no + 1
				local code = strip_comments(line)
				if code:match("%S") then
					for _, rule in ipairs(FORBIDDEN_TOKEN_PATTERNS) do
						if code:find(rule.pattern) then
							hits[#hits + 1] = string.format(
								"%s:%d %s",
								rel_path(path),
								line_no,
								rule.label
							)
						end
					end
					for _, prefix in ipairs(FORBIDDEN_REQUIRE_PREFIXES) do
						if code:find('require%("' .. prefix) or code:find("require%('" .. prefix) then
							hits[#hits + 1] = string.format(
								"%s:%d forbidden require(%s)",
								rel_path(path),
								line_no,
								prefix .. "*"
							)
						end
					end
				end
			end
			file:close()
		end
	end
	table.sort(hits)
	return hits
end

return M
