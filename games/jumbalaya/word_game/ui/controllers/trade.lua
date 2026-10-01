--[[ word_game/ui/controllers/trade.lua - Marketplace overlay controls ]]

local action_dispatch = require("app.input.action_dispatch")
local TradeUI = require("word_game.ui.trade")
local market_actions = require("word_game.ui.trade.actions")

local M = {}

function M.on_close(_e)
	action_dispatch.dispatch_func("trade_close")
	TradeUI.close()
end

function M.on_market_add(e)
	market_actions.on_add(e)
end

function M.on_market_remove(e)
	market_actions.on_remove(e)
end

function M.on_market_modify(e)
	market_actions.on_modify(e)
end

function M.on_pick(e)
	action_dispatch.dispatch_func("trade_pick")
	TradeUI.on_pick(e)
end

function M.on_skip_add(e)
	action_dispatch.dispatch_func("trade_skip_add")
	TradeUI.on_skip_add(e)
end

function M.on_skip_remove(e)
	action_dispatch.dispatch_func("trade_skip_remove")
	TradeUI.on_skip_remove(e)
end

function M.on_skip(e)
	action_dispatch.dispatch_func("trade_skip")
	TradeUI.on_skip_add(e)
end

return M
