--[[ word_game/ui/trade/actions.lua - Marketplace add / remove / modify handlers ]]

local facade = require("word_game.ui.facade")
local TradeUI = require("word_game.ui.trade")
local offer_mod = require("word_game.ui.trade.offer")
local word_feedback = require("word_game.ui.feedback.word_feedback")

local M = {}

local function item_from_event(e)
	local node = e
	while node do
		local ref = node.config and node.config.ref_table
		if ref then
			if ref.item then
				return ref.item
			end
			if ref.market_index then
				local items = offer_mod.items()
				return items[ref.market_index]
			end
		end
		node = node.config and node.config.button_UIE
	end
end

local function apply_action(e, action)
	local trade = facade.trade()
	local item = item_from_event(e)
	if not item then
		word_feedback.show("No card selected")
		return
	end
	local ok, err = trade.apply(item, { action = action })
	if not ok then
		word_feedback.show(err or "Could not complete action")
		return
	end
	local deck = facade.deck()
	if deck and deck.sync_deck_count_display then
		deck.sync_deck_count_display()
	end
	TradeUI.close()
end

function M.on_add(e)
	apply_action(e, "add")
end

function M.on_remove(e)
	apply_action(e, "remove")
end

function M.on_modify(e)
	apply_action(e, "modifier")
end

return M
