--[[ word_game/ui/trade/actions.lua - Marketplace add / remove / modify handlers ]]

local facade = require("word_game.ui.facade")
local offer_mod = require("word_game.ui.trade.offer")
local refresh = require("word_game.ui.trade.refresh")
local card_fly = require("word_game.ui.trade.card_fly")
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
				return items[ref.market_index], ref.market_index
			end
		end
		node = node.config and node.config.button_UIE
	end
end

local function spent_for_action(trade, action)
	local costs = trade.ACTION_COSTS
	if action == "remove" then
		return costs.remove
	end
	if action == "modifier" then
		return costs.modifier
	end
	return costs.add
end

local function apply_action(e, action)
	if card_fly.is_active() then
		return
	end
	local trade = facade.trade()
	local item, market_index = item_from_event(e)
	if not item then
		word_feedback.show("No card selected")
		return
	end
	local ok, err = trade.apply(item, { action = action })
	if not ok then
		word_feedback.show(err or "Could not complete action")
		return
	end
	local spent = spent_for_action(trade, action)
	if action == "add" then
		local deck = facade.deck()
		if deck and deck.sync_deck_count_display then
			deck.sync_deck_count_display()
		end
		local started = card_fly.start_add_fly({
			item = item,
			market_index = market_index or 1,
			on_complete = function()
				refresh.after_tokens_changed({ spent = spent })
			end,
		})
		if not started then
			refresh.after_tokens_changed({ spent = spent })
		end
		return
	end
	refresh.after_tokens_changed({ spent = spent })
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
