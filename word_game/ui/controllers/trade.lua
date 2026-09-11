--[[ word_game/ui/controllers/trade.lua - Phase 4 trade runtime().FUNCS controller ]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local action_dispatch = require("bridge.action_dispatch")
local TradeUI = require("word_game.ui.trade")

local M = {}

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
