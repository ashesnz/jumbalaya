--[[ word_game/ui/callbacks/trade.lua - Card Marketplace Funcs registration ]]

local TradeController = require("word_game.ui.controllers.trade")
local Funcs = require("app.callbacks.funcs")

Funcs.register("trade_close", TradeController.on_close)
Funcs.register("trade_market_add", TradeController.on_market_add)
Funcs.register("trade_market_remove", TradeController.on_market_remove)
Funcs.register("trade_market_modify", TradeController.on_market_modify)
Funcs.register("trade_pick", TradeController.on_pick)
Funcs.register("trade_skip_add", TradeController.on_skip_add)
Funcs.register("trade_skip_remove", TradeController.on_skip_remove)
Funcs.register("trade_skip", TradeController.on_skip)
