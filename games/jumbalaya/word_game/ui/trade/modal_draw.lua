--[[ word_game/ui/trade/modal_draw.lua - Paint marketplace overlay above all table chrome ]]

local game = require("word_game.ui.util.game_runtime").game

local M = {}

function M.is_marketplace_overlay()
	return WORD_GAME_UI
		and WORD_GAME_UI.TradeUI
		and WORD_GAME_UI.TradeUI.is_open
		and WORD_GAME_UI.TradeUI.is_open()
end

--- Overlay panels skip a second draw in the same frame unless we reset the guard.
function M.draw_overlay_on_top()
	local menu = game().OVERLAY_MENU
	if not M.is_marketplace_overlay() or not menu or menu.REMOVED then
		return
	end
	if menu.FRAME then
		menu.FRAME.RENDER = (game().FRAMES.RENDER or 1) - 1
	end
	love.graphics.push()
	menu:translate_container()
	menu:draw()
	love.graphics.pop()
end

return M
