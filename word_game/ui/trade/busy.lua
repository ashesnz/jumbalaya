--[[ word_game/ui/trade/busy.lua - Push trade animation busy flag to G.GAME ]]

local Busy = require("word_game.model.run.busy")

local M = {}

function M.sync()
	local fly = require("word_game.ui.trade.fly")
	local animate = require("word_game.ui.trade.animate")
	Busy.set("trade_ui_busy", fly.is_flying() or animate.is_transforming())
end

return M
