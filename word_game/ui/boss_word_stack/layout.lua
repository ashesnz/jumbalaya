--[[ word_game/ui/boss_word_stack/layout.lua - Bonus gutter geometry ]]

local model = require("word_game.model.bonus_stack")
local gutter = require("word_game.board.bonus_gutter")

local M = {}

M.LEFT_WINDOW_MARGIN = gutter.LEFT_WINDOW_MARGIN
M.STACK_Y_LIFT_PX = gutter.STACK_Y_LIFT_PX

local function gameplay_left_edge()
	local edge
	if G.hand and G.hand.T then
		edge = G.hand.T.x
	end
	local area = G.placement_table and G.placement_table.area
	if area and area.T then
		if edge then
			edge = math.min(edge, area.T.x)
		else
			edge = area.T.x
		end
	end
	if not edge then
		local felt = require("word_game.ui.layout.felt")
		edge = felt.play_column().x
	end
	return edge
end

function M.stack_y_lift()
	return gutter.stack_y_lift()
end

function M.stack_layout()
	return gutter.stack_layout()
end

function M.clears_gameplay_bounds()
	local layout = M.stack_layout()
	local left_edge = gameplay_left_edge()
	return layout.x + layout.card_w + layout.clearance <= left_edge + 0.02
end

function M.target_position(index)
	return gutter.target_position(index)
end

function M.gutter_pixels(layout)
	return gutter.gutter_pixels(layout)
end

function M.return_card(card)
	return gutter.return_card(card)
end

function M.point_in_stack(x, y)
	return gutter.point_in_stack(x, y)
end

function M.drop_in_gutter(session, x, y)
	return gutter.drop_in_gutter(session, x, y)
end

return M
