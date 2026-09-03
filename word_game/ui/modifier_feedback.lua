--[[ word_game/ui/modifier_feedback.lua - Floating modifier hint above a placed card ]]

local deck = require("word_game.model.cards.deck")

local M = {}

local DEFAULT_COLOUR = { 1, 0.85, 0.2, 1 }

function M.show_on_placed_card(card)
	if not card then return end
	if not deck.is_modified(card) then return end
	local text = deck.modifier_ui_text(deck.card_letter(card))
	if not text then return end
	local FloatUp = WORD_GAME and WORD_GAME.FloatUpText
	if not FloatUp or not FloatUp.from_card then return end
	FloatUp.from_card(card, text, {
		colour = G.C and G.C.GOLD or DEFAULT_COLOUR,
		font_px = 26,
		life = 1.35,
		speed = 1.2,
	})
end

return M
