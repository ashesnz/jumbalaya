--[[ word_game/ui/trade/preview.lua - Marketplace letter card previews (not added to deck) ]]

local game = require("word_game.ui.util.game_runtime").game
local facade = require("word_game.ui.facade")

local deck = facade.deck()

local M = {}

local function scale_card(card, w, h)
	if not card or not card.T then return end
	card.T.w = w
	card.T.h = h
	if card.VT then
		card.VT.w = w
		card.VT.h = h
	end
end

function M.ensure(item, card_w, card_h)
	if not item then return nil end
	if item.preview and not item.preview.REMOVED then
		scale_card(item.preview, card_w, card_h)
		return item.preview
	end
	if item.card and not item.card.REMOVED then
		item.preview = item.card
		scale_card(item.preview, card_w, card_h)
		return item.preview
	end
	if not Card then return nil end
	local g = game()
	local letter = item.letter
	local color = item.color
	local center = deck.letter_center()
	if not center or not center.config then
		return nil
	end
	local front = deck.front(letter, color)
	local card = Card(
		0, 0,
		card_w or (g.CARD_W or 1) * 0.82,
		card_h or (g.CARD_H or 1.4) * 0.82,
		front,
		center,
		{}
	)
	deck.tag_card(card, letter, color)
	card.states.drag.can = false
	card.states.hover.can = false
	card.states.click.can = false
	card.states.collide.can = false
	item.preview = card
	item.preview_is_standalone = true
	return card
end

function M.teardown_offer(offer)
	local letters = offer and offer.add and offer.add.letters
	if not letters then return end
	for _, item in ipairs(letters) do
		if item.preview_is_standalone and item.preview and item.preview ~= item.card then
			if item.preview.remove then
				item.preview:remove()
			else
				item.preview.REMOVED = true
			end
		end
		item.preview = nil
		item.preview_is_standalone = nil
	end
end

return M
