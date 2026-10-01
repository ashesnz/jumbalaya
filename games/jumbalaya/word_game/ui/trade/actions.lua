--[[ word_game/ui/trade/actions.lua - Marketplace add / remove / modify handlers ]]

local facade = require("word_game.ui.facade")
local TradeUI = require("word_game.ui.trade")
local word_feedback = require("word_game.ui.feedback.word_feedback")

local M = {}

local function item_from_event(e)
	local ref = e and e.config and e.config.ref_table
	return ref and ref.item
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
