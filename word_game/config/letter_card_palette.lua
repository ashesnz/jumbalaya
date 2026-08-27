--[[
	letter_card_palette.lua - Runtime fill colours for letter-card backgrounds.

	Deck faces are drawn as a white frame sprite tinted with `fill`, plus a
	shared letter-glyph atlas on top. Add new palette keys here when you ship
	alternate deck backs / colour themes.
]]

---@class LetterCardPalette
local M = {}

M.schemes = {
	default = {
		red = { 0.494, 0.068, 0.066, 1 },
		black = { 0.10, 0.10, 0.12, 1 },
	},
	colourblind = {
		red = { 0.95, 0.55, 0.10, 1 },
		black = { 0.20, 0.45, 0.85, 1 },
	},
}

--- UI/history tiles reuse the same fills.
M.tile = M.schemes

function M.scheme(colourblind)
	return colourblind and M.schemes.colourblind or M.schemes.default
end

function M.fill(color_key, colourblind)
	local scheme = M.scheme(colourblind)
	return scheme[color_key] or scheme.black
end

function M.ui_color(color_key, colourblind)
	return M.fill(color_key, colourblind)
end

return M
