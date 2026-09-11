--[[ word_game/ui/callbacks/trade.lua - Card Marketplace runtime().FUNCS registration ]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local TradeController = require("word_game.ui.controllers.trade")

runtime().FUNCS.trade_pick = TradeController.on_pick
runtime().FUNCS.trade_skip_add = TradeController.on_skip_add
runtime().FUNCS.trade_skip_remove = TradeController.on_skip_remove
runtime().FUNCS.trade_skip = TradeController.on_skip
