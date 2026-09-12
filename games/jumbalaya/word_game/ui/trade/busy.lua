--[[ word_game/ui/trade/busy.lua - Push trade animation busy flag via Busy model ]]


local facade = require("word_game.ui.facade")
local Busy = facade.busy()
local M = {}

function M.sync()
	local fly = require("word_game.ui.trade.fly")
	local animate = require("word_game.ui.trade.animate")
	Busy.set("trade_ui_busy", fly.is_flying() or animate.is_transforming())
end

return M
