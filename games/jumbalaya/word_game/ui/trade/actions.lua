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
				return ref.item, ref.market_index
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

local function finalize_trade(trade, action, item)
	if action == "add" then
		return trade.finalize_add(item)
	end
	if action == "remove" then
		return trade.finalize_remove(item)
	end
	return trade.finalize_modifier(item)
end

local function after_success(_trade, _action, _item, spent)
	local deck = facade.deck()
	if deck and deck.sync_deck_count_display then
		deck.sync_deck_count_display()
	end
	if WORD_GAME_UI and WORD_GAME_UI.TableInput and WORD_GAME_UI.TableInput.refresh_card_input then
		WORD_GAME_UI.TableInput.refresh_card_input()
	end
	refresh.after_tokens_changed({ spent = spent })
end

local function run_with_animation(e, action)
	if card_fly.is_active() then
		return
	end
	local trade = facade.trade()
	local item, market_index = item_from_event(e)
	if not item then
		word_feedback.show("No card selected")
		return
	end
	local ok, err = trade.apply(item, { action = action, defer_effect = true })
	if not ok then
		word_feedback.show(err or "Could not complete action")
		return
	end
	local spent = spent_for_action(trade, action)
	local fly_kind = action == "modifier" and "modify" or action
	local started = card_fly.start({
		kind = fly_kind,
		item = item,
		market_index = market_index or 1,
		on_complete = function()
			local fin_ok, fin_err = finalize_trade(trade, action, item)
			if not fin_ok then
				word_feedback.show(fin_err or "Could not complete action")
			end
			after_success(trade, action, item, spent)
		end,
	})
	if not started then
		local fin_ok, fin_err = finalize_trade(trade, action, item)
		if not fin_ok then
			word_feedback.show(fin_err or "Could not complete action")
			return
		end
		after_success(trade, action, item, spent)
	end
end

function M.on_add(e)
	run_with_animation(e, "add")
end

function M.on_remove(e)
	run_with_animation(e, "remove")
end

function M.on_modify(e)
	run_with_animation(e, "modifier")
end

return M
