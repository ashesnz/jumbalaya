--[[ word_game/ui/trade/nodes/face.lua - Marketplace letter face card nodes ]]

local game = require("word_game.ui.util.game_runtime").game

local facade = require("word_game.ui.facade")
local game_access = facade.game_access()

local M = {}

function M.make_face_card(item, w, h, deck_model)
	if not game_access.get() or not game().LETTERS.faces or not deck_model().letter_center() then
		return nil
	end
	if not item or not item.letter then return nil end
	local front = deck_model().front(item.letter, item.color)
	if not front then return nil end
	local card = Card(0, 0, w, h, front, deck_model().letter_center(), {
		bypass_discovery_center = true,
		bypass_discovery_ui = true,
		bypass_lock = true,
	})
	card.created_on_pause = true
	card.states.drag.can = false
	card.states.collide.can = false
	card.states.hover.can = false
	card.states.click.can = false
	deck_model().tag_card(card, item.letter, item.color)
	card.T.r = 0
	return card
end

function M.face_node(item, market_card_scale, deck_model, trade_model)
	if item.flying then
		return { n = game().UI.ROW, config = { align = "cm", minw = game().CARD_W * market_card_scale, minh = game().CARD_H * market_card_scale }, nodes = {} }
	end
	if item.removed or (item.mode == "remove" and not trade_model().item_in_deck(item)) then
		return { n = game().UI.ROW, config = { align = "cm", minw = game().CARD_W * market_card_scale, minh = game().CARD_H * market_card_scale }, nodes = {} }
	end
	local w, h = game().CARD_W * market_card_scale, game().CARD_H * market_card_scale
	local card = M.make_face_card(item, w, h, deck_model)
	item.market_card = card
	if card then
		return { n = game().UI.OBJECT, config = { object = card, w = w, h = h } }
	end
	return { n = game().UI.TEXT, config = {
		text = item and item.letter or "?",
		scale = 0.8,
		colour = game().C.WHITE,
		shadow = true,
	}}
end

return M
