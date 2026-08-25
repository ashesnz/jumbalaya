-- word_game/ui/number_format.lua - compact number formatting and UI scale helpers.

function number_format(value)
	G.E_SWITCH_POINT = G.E_SWITCH_POINT or 100000000000
	if not value or type(value) ~= "number" then
		return value or ""
	end
	if value >= G.E_SWITCH_POINT then
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

function score_number_scale(scale, amount)
	G.E_SWITCH_POINT = G.E_SWITCH_POINT or 100000000000
	if type(amount) ~= "number" or amount >= G.E_SWITCH_POINT then
		return 0.7 * (scale or 1)
	end
	if amount >= 1000000 then
		return 14 * 0.75 / (math.floor(math.log(amount)) + 4) * (scale or 1)
	end
	return 0.75 * (scale or 1)
end

return true
