--[[ word_game/ui/callbacks/trade.lua - Card Marketplace overlay G.FUNCS ]]

local TradeUI = require("word_game.ui.trade")

G.FUNCS.trade_pick = function(e)
	TradeUI.on_pick(e)
end

G.FUNCS.trade_skip_add = function()
	TradeUI.on_skip_add()
end

G.FUNCS.trade_skip_remove = function()
	TradeUI.on_skip_remove()
end

G.FUNCS.trade_skip = G.FUNCS.trade_skip_add
