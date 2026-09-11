--[[ word_game/ui/callbacks/trade.lua - Card Marketplace runtime().FUNCS registration ]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local TradeController = require("word_game.ui.controllers.trade")
local Funcs = require("bridge.funcs_registry")

Funcs.register("trade_pick", TradeController.on_pick)
Funcs.register("trade_skip_add", TradeController.on_skip_add)
Funcs.register("trade_skip_remove", TradeController.on_skip_remove)
Funcs.register("trade_skip", TradeController.on_skip)
