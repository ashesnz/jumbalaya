--[[ word_game/ui/table/controls/play_hold_redraw/button.lua - Play button press detection ]]

local GameRT = require("word_game.ui.util.game_runtime")

local M = {}

local function runtime()
	return GameRT.game()
end

function M.gameplay_overlays_active()
	if WORD_GAME_UI.TradeUI and WORD_GAME_UI.TradeUI.is_open and WORD_GAME_UI.TradeUI.is_open() then
		return true
	end
	return false
end

function M.play_button_uie()
	return WORD_GAME_UI.TableControls and WORD_GAME_UI.TableControls.play_button_uie()
end

local function belongs_to_play_button(node)
	local btn = M.play_button_uie()
	if not btn or not node then return false end
	if node == btn then return true end
	local n = node
	while n do
		if n == btn then return true end
		if n.config and n.config.id == "hand_play_button" then return true end
		n = n.parent
	end
	return false
end

function M.is_pressing_play()
	local btn = M.play_button_uie()
	if not btn or not btn.states.visible or not btn.config.button then return false end

	local c = runtime().INPUT
	local press_state = (c and c.pointer_held) or (love.mouse and love.mouse.isDown and love.mouse.isDown(1))
	if not press_state then return false end

	if btn.states.collide and btn.states.collide.is then return true end
	if btn.states.hover and btn.states.hover.is then return true end

	for _, node in ipairs((c and c.collision_list) or {}) do
		if belongs_to_play_button(node) then return true end
	end

	for _, node in ipairs((c and c.nodes_at_cursor) or {}) do
		if belongs_to_play_button(node) then return true end
	end

	local pt = runtime().POINTER and runtime().POINTER.T
	if pt and btn.collides_with_point and btn:collides_with_point(pt) then return true end

	return false
end

return M
