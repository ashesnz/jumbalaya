--[[
	word_game/model/layout/request.lua - Sets live_game().pending_layout for deferred TABLE_BOARD relayout

	Core: none
	Store: none
	Presentation: none — sets pending_layout; UI loop applies relayout
]]

local live_game = require("word_game.model.live_game")

local M = {}

function M.refresh()
	local g = live_game()
	if g then
		g.pending_layout = true
	end
end

return M
