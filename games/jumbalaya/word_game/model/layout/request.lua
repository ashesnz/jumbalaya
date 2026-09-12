--[[
	word_game/model/layout/request.lua - Sets live_game().ARGS.pending_layout for deferred TABLE_BOARD relayout

	Core: none
	Store: none
	Presentation: none — sets ARGS.pending_layout; UI loop applies relayout
]]

local live_game = require("word_game.model.live_game")

local M = {}

function M.refresh()
	live_game().ARGS = live_game().ARGS or {}
	live_game().ARGS.pending_layout = true
end

return M
