--[[
	letter_card_palette.lua - Runtime fill colours for letter-card backgrounds.

	Fill RGBA values come from deck_face_colors.lua. Default red is #7e1011.
]]

local DeckColors = require "word_game.config.deck_face_colors"

---@class LetterCardPalette
local M = {}

--- Face colour used for every card in the starter deck and other new cards
--- until a different suit is chosen (marketplace transform, etc.).
M.DEFAULT_FACE_COLOR = "red"

--- Face colour applied after the marketplace Modify transform animation.
M.MODIFIED_FACE_COLOR = "modified"

M.schemes = {
	default = {
		red = DeckColors.red,
		black = DeckColors.black,
		modified = DeckColors.modified,
	},
	colourblind = {
		red = { 0.95, 0.55, 0.10, 1 },
		black = { 0.20, 0.45, 0.85, 1 },
		modified = DeckColors.modified,
	},
}

--- UI/history tiles reuse the same fills.
M.tile = M.schemes

function M.scheme(colourblind)
	return colourblind and M.schemes.colourblind or M.schemes.default
end

function M.fill(color_key, colourblind)
	local scheme = M.scheme(colourblind)
	return scheme[color_key] or scheme[M.DEFAULT_FACE_COLOR]
end

function M.ui_color(color_key, colourblind)
	return M.fill(color_key, colourblind)
end

function M.default_fill(colourblind)
	return M.fill(M.DEFAULT_FACE_COLOR, colourblind)
end

return M
