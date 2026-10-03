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
	-- Never embed the live deck card: it keeps draw-pile/world transforms and
	-- renders outside the marketplace cell (often the right-hand offer column).
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
		card_w or g.CARD_W or 1,
		card_h or g.CARD_H or 1.4,
		front,
		center,
		{}
	)
	deck.tag_card(card, letter, color)
	if item.card and not item.card.REMOVED and deck.is_modified and deck.is_modified(item.card) then
		deck.apply_to_card(card)
	end
	if card.hard_set_T then
		card:hard_set_T(0, 0, card_w, card_h)
	end
	if card.set_scene_parent then
		card:set_scene_parent(nil)
	end
	card.states.drag.can = false
	card.states.hover.can = false
	card.states.click.can = false
	card.states.collide.can = false
	item.preview = card
	item.preview_is_standalone = true
	return card
end

function M.discard_item_preview(item)
	if not item then return end
	local card = item.preview
	if item.preview_is_standalone and card and not card.REMOVED then
		if card.remove then
			card:remove()
		else
			card.REMOVED = true
		end
	end
	item.preview = nil
	item.preview_is_standalone = nil
end

function M.refresh_market_slot(menu, index)
	if not menu or not menu.find_node_by_id then return end
	local offer_mod = require("word_game.ui.trade.offer")
	local items = offer_mod.items()
	local item = items[index]
	local node = menu:find_node_by_id("trade_market_card_" .. index)
	if not node or not node.config or not item then return end
	local g = game()
	local card_w = (g.CARD_W or 1) * 0.5
	local card_h = (g.CARD_H or 1.4) * 0.5
	local card = M.ensure(item, card_w, card_h)
	if not card then
		return
	end
	node.config.object = card
	if card.states then
		card.states.visible = true
	end
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
