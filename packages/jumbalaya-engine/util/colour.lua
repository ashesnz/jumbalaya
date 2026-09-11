--[[
	app/core/util/colour.lua - colour parsing and blending.

	Colours are `{r, g, b, a}` tables with 0..1 components. These helpers sit
	at the engine level (the UI renderer itself uses them), so they are also
	installed as globals while game code migrates to module requires.
]]

-- Channel defaults applied when an operand omits one: grey for RGB, opaque
-- for alpha.
local CHANNEL_DEFAULTS = {0.5, 0.5, 0.5, 1}

--- Parses a 6- or 8-digit hex string (`"RRGGBB"` / `"RRGGBBAA"`).
---@param hex string
---@return table {r, g, b, a}
function colour_from_hex(hex)
	if #hex <= 6 then hex = hex .. "FF" end
	local _, _, r, g, b, a = hex:find('(%x%x)(%x%x)(%x%x)(%x%x)')
	return {(tonumber(r, 16) or 0) / 255, (tonumber(g, 16) or 0) / 255,
		(tonumber(b, 16) or 0) / 255, (tonumber(a, 16) or 0) / 255}
end

--- Linear blend of two colours; `weight` is the share given to `first`.
---@param first table
---@param second table
---@param weight number 0..1
---@return table
function blend_colours(first, second, weight)
	local blended = {}
	for channel = 1, 4 do
		local fa = first[channel] or CHANNEL_DEFAULTS[channel]
		local fb = second[channel] or CHANNEL_DEFAULTS[channel]
		blended[channel] = fa * weight + fb * (1 - weight)
	end
	return blended
end

--- Nudges each RGB channel toward `ceiling` by `amount`, leaving alpha fixed.
--  Shared engine for tint/shade; `toward_white` picks the direction.
local function shift_channels(colour, amount, toward_white)
	local shifted = {}
	for channel = 1, 3 do
		shifted[channel] = colour[channel] * (1 - amount) + (toward_white and amount or 0)
	end
	shifted[4] = colour[4]
	return shifted
end

--- Washes a colour out toward white.
---@param unpacked boolean return components loose instead of as a table
function tint(colour, amount, unpacked)
	local shifted = shift_channels(colour, amount, true)
	if unpacked then return shifted[1], shifted[2], shifted[3], shifted[4] end
	return shifted
end

--- Sinks a colour toward black.
---@param unpacked boolean return components loose instead of as a table
function shade(colour, amount, unpacked)
	local shifted = shift_channels(colour, amount, false)
	if unpacked then return shifted[1], shifted[2], shifted[3], shifted[4] end
	return shifted
end

--- Recolours a colour with `alpha`, keeping its channels.
---@param unpacked boolean return components loose instead of as a table
function with_alpha(colour, alpha, unpacked)
	if unpacked then return colour[1], colour[2], colour[3], alpha end
	return {colour[1], colour[2], colour[3], alpha}
end

return {
	colour_from_hex = colour_from_hex,
	blend_colours = blend_colours,
	tint = tint,
	shade = shade,
	with_alpha = with_alpha,
}
