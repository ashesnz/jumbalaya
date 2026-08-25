--[[
	app/core/util/pack.lua - table <-> Lua-source serialization plus
	deflate-compressed save file IO.

	Save format contract:
	  - `pack_to_source` emits executable Lua source (`"return {...}"` at the
	    top level, bare `{...}` for nested tables).
	  - Live engine objects are stored as the `"MANUAL_REPLACE"` sentinel and
	    rebuilt by callers on load (mirrors `save_safe_clone`).
	  - Files written by `write_save_file` are deflate-compressed; payloads that
	    already start with `'return'` are treated as plain source.
]]

local Kind = require("app.core.object")

-- Sentinel string stored in save files in place of unserializable engine objects.
local LIVE_OBJECT_SENTINEL = [["MANUAL_REPLACE"]]

--- Renders one value as literal Lua source.
local function serialize_value(value)
	local kind = type(value)
	if kind == "table" then
		return (value.is_kind and value:is_kind(Kind)) and LIVE_OBJECT_SENTINEL
			or pack_to_source(value, true)
	elseif kind == "string" then
		return string.format("%q", value)
	elseif kind == "boolean" then
		return tostring(value)
	end
	return tostring(value)
end

--- Renders one key as a bracketed Lua table key.
local function serialize_key(key)
	if type(key) == "string" then return ('[%s]'):format(string.format("%q", key)) end
	return ("[%s]"):format(tostring(key))
end

--- Serializes a table to Lua source. Top level is prefixed with `return`;
--- nested tables (via the internal `nested` flag) emit bare `{...}`. Table
--- keys are rejected: saves are flat-keyed by strings and numbers.
function pack_to_source(data, nested)
	local chunks = {nested and "{" or "return {"}

	for key, value in pairs(data) do
		assert(type(key) ~= "table", "Data table cannot have a table as a key reference")
		chunks[#chunks + 1] = serialize_key(key) .. "=" .. serialize_value(value) .. ","
	end

	chunks[#chunks + 1] = "}"
	return table.concat(chunks)
end

--- Evaluates Lua source produced by `pack_to_source` back into a table.
---@param source string
---@return table
function unpack_source(source)
	local compile = loadstring or load
	return assert(compile(source))()
end

--- Reads a save payload, transparently inflating deflate-compressed files.
--  Plain source payloads (starting with `'return'`) pass through untouched.
---@param path string
---@return string|nil
function read_save_payload(path)
	if not love.filesystem.getInfo(path) then return end

	local contents = love.filesystem.read(path)
	if not contents or contents == '' then return end

	if string.sub(contents, 1, 6) ~= 'return' then
		local inflated
		inflated, contents = pcall(love.data.decompress, 'string', 'deflate', contents)
		if not inflated then return nil end
	end

	return contents
end

--- Serializes (when handed a table), deflate-compresses, and stores a save file.
---@param path string
---@param data table|string
function write_save_file(path, data)
	local source = type(data) == 'table' and pack_to_source(data) or data
	love.filesystem.write(path, love.data.compress('string', 'deflate', source, 1))
end

return {
	pack_to_source = pack_to_source,
	unpack_source = unpack_source,
	read_save_payload = read_save_payload,
	write_save_file = write_save_file,
}
