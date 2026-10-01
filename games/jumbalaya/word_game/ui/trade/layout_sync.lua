--[[ word_game/ui/trade/layout_sync.lua - Finalize marketplace overlay alignment ]]

local M = {}

function M.sync_overlay(overlay)
	if not overlay or not overlay.recalculate then return end
	overlay:recalculate()
end

return M
