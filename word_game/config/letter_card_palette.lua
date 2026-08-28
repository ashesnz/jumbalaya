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

--- Face colour applied to boss-word bonus cards after the gold transform.
M.BONUS_FACE_COLOR = "gold"

M.schemes = {
	default = {
		red = DeckColors.red,
		black = DeckColors.black,
		modified = DeckColors.modified,
		gold = DeckColors.gold,
	},
}

--- UI/history tiles reuse the same fills.
M.tile = M.schemes

function M.scheme()
	return M.schemes.default
end

function M.fill(color_key)
	local scheme = M.scheme()
	return scheme[color_key] or scheme[M.DEFAULT_FACE_COLOR]
end

function M.ui_color(color_key)
	return M.fill(color_key)
end

function M.default_fill()
	return M.fill(M.DEFAULT_FACE_COLOR)
end

return M
