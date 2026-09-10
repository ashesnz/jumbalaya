--[[ word_game/ui/callbacks/trade.lua - Card Marketplace G.FUNCS registration ]]

local TradeUI = require("word_game.ui.trade")

G.FUNCS.trade_pick = TradeUI.on_pick
G.FUNCS.trade_skip_add = TradeUI.on_skip_add
G.FUNCS.trade_skip_remove = TradeUI.on_skip_remove
G.FUNCS.trade_skip = TradeUI.on_skip_add
