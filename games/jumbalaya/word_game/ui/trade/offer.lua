--[[ word_game/ui/trade/offer.lua - Roll and cache marketplace offers for the open overlay ]]

local facade = require("word_game.ui.facade")
local session_state = require("word_game.ui.trade.session_state")

local M = {}

function M.prepare()
	local trade = facade.trade()
	local offer = trade.roll_offer()
	trade.sync_offer_cards(offer)
	session_state.set_offer(offer)
	return offer
end

function M.current()
	return session_state.offer()
end

function M.items()
	local offer = M.current()
	return (offer and offer.add and offer.add.letters) or {}
end

return M
