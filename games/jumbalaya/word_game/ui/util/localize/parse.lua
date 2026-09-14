--[[ word_game/ui/util/localize/parse.lua - Markup parser and UTF-8 helpers ]]

local M = {}

--- Appends a literal run, dropping empties (and whitespace under `X` styles).
local function push_literal(runs, text, strip_spaces)
	if strip_spaces then
		text = text:gsub("%s+", "")
	end
	if text ~= "" then
		runs[#runs + 1] = text
	end
end

--- Splits styled text on `#ref#` markers into literal and reference runs.
local function split_text_runs(text, strip_spaces)
	local runs = {}
	local i, n = 1, #text
	while i <= n do
		local open = text:find("#", i, true)
		push_literal(runs, text:sub(i, (open or n + 1) - 1), strip_spaces)
		if not open then
			break
		end

		local close = text:find("#", open + 1, true)
		if close then
			runs[#runs + 1] = { text:sub(open + 1, close - 1) }
			i = close + 1
		else
			break
		end
	end
	return runs
end

--- Parses the body of one `{...}` section into a style table.
local function parse_control(body)
	local control = {}
	if body == "" then
		return control
	end
	for field in body:gmatch("[^,]+") do
		local name, value = field:match("^([^:]*)[:](.*)$")
		if name and value ~= nil and name ~= "" then
			control[name] = value
		end
	end
	return control
end

function M.parse_string(line)
	local parts = {}
	if type(line) ~= "string" then
		return parts
	end

	local control = {}
	local pos = 1
	while pos <= #line do
		local open = line:find("{", pos, true)
		local text = line:sub(pos, (open or #line + 1) - 1)
		if text ~= "" then
			parts[#parts + 1] = {
				strings = split_text_runs(text, control.X ~= nil),
				control = control,
			}
		end
		if not open then
			break
		end

		local close = line:find("}", open + 1, true)
		control = parse_control(line:sub(open + 1, (close or #line + 1) - 1))
		pos = (close or #line + 1) + 1
	end
	return parts
end

local utf8 = { pattern = "[%z\1-\127\194-\244][\128-\191]*" }

utf8.map = function(s, f, no_subs)
	local i = 0
	if no_subs then
		for b, e in s:gmatch("()" .. utf8.pattern .. "()") do
			i = i + 1
			local c = e - b
			f(i, c, b)
		end
	else
		for b, c in s:gmatch("()(" .. utf8.pattern .. ")") do
			i = i + 1
			f(i, c, b)
		end
	end
end

utf8.chars = function(s, no_subs)
	return coroutine.wrap(function()
		return utf8.map(s, coroutine.yield, no_subs)
	end)
end

M.utf8 = utf8

function M.each_utf8_char(s)
	return s:gmatch(utf8.pattern)
end

return M
