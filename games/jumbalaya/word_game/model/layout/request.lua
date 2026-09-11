--[[ word_game/model/layout/request.lua - Deferred TABLE_BOARD layout refresh (model-safe) ]]

local live_game = require("word_game.model.live_game")

local M = {}

function M.refresh()
	live_game().ARGS = live_game().ARGS or {}
	live_game().ARGS.pending_layout = true
end

return M
