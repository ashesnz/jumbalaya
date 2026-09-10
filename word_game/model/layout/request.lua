--[[ word_game/model/layout/request.lua - Deferred TABLE_BOARD layout refresh (model-safe) ]]

local M = {}

function M.refresh()
	G.ARGS = G.ARGS or {}
	G.ARGS.pending_layout = true
end

return M
