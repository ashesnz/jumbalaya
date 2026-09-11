--[[ jumbalaya-engine/util/number_format.lua - Compact number formatting and UI scale helpers ]]

local shell = require("jumbalaya-engine.shell")

local M = {}

local DEFAULT_SWITCH_POINT = 100000000000

local function switch_point()
	local game = shell.game()
	return (game and game.E_SWITCH_POINT) or DEFAULT_SWITCH_POINT
end

function M.number_format(value)
	local threshold = switch_point()
	if not value or type(value) ~= "number" then
		return value or ""
	end
	if value >= threshold then
		local scientific = string.format("%.4g", value)
		local exponent = math.floor(math.log(tonumber(scientific), 10))
		return string.format("%.3f", scientific / (10 ^ exponent)) .. "e" .. exponent
	end

	local pattern = value ~= math.floor(value)
		and (value >= 100 and "%.0f" or value >= 10 and "%.1f" or "%.2f")
		or "%.0f"
	return string.format(pattern, value)
		:reverse()
		:gsub("(%d%d%d)", "%1,")
		:gsub(",$", "")
		:reverse()
end

function M.score_number_scale(scale, amount)
	local threshold = switch_point()
	if type(amount) ~= "number" or amount >= threshold then
		return 0.7 * (scale or 1)
	end
	if amount >= 1000000 then
		return 14 * 0.75 / (math.floor(math.log(amount)) + 4) * (scale or 1)
	end
	return 0.75 * (scale or 1)
end

return M
