--[[
	word_game/config/env.lua - Environment variable and .env overrides.

	Shell env takes precedence over values from a project-root `.env` file.
	Truthy: 1, true, yes, on (case-insensitive). Falsy: 0, false, no, off.
]]

local M = {}

local dotenv = {}

local TRUTHY = { ["1"] = true, ["true"] = true, ["yes"] = true, ["on"] = true }
local FALSY = { ["0"] = false, ["false"] = false, ["no"] = false, ["off"] = false }

local function trim(value)
	if value == nil then return nil end
	return value:match("^%s*(.-)%s*$")
end

local function parse_bool(raw)
	if raw == nil or raw == "" then return nil end
	local key = trim(raw):lower()
	if TRUTHY[key] then return true end
	if FALSY[key] then return false end
	return nil
end

local function load_dotenv()
	local file = io.open(".env", "r")
	if not file then return end
	for line in file:lines() do
		local trimmed = trim(line)
		if trimmed and trimmed ~= "" and not trimmed:match("^#") then
			local key, value = trimmed:match("^([^=]+)=(.*)$")
			if key then
				key = trim(key)
				value = trim(value)
				value = value:gsub("^[\"']", ""):gsub("[\"']$", "")
				if dotenv[key] == nil and os.getenv(key) == nil then
					dotenv[key] = value
				end
			end
		end
	end
	file:close()
end

function M.get_raw(key)
	local from_os = os.getenv(key)
	if from_os ~= nil then return from_os end
	return dotenv[key]
end

function M.flag(key)
	return parse_bool(M.get_raw(key))
end

load_dotenv()

return M
