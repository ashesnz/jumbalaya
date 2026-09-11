--[[ word_game/ui/callbacks/trade.lua - Card Marketplace G.FUNCS registration ]]

local TradeController = require("word_game.ui.controllers.trade")

G.FUNCS.trade_pick = TradeController.on_pick
G.FUNCS.trade_skip_add = TradeController.on_skip_add
G.FUNCS.trade_skip_remove = TradeController.on_skip_remove
G.FUNCS.trade_skip = TradeController.on_skip
