--[[ word_game/ui/boss_word_stack.lua - Boss word success card stack display ]]

local placement_layout = require("word_game.ui.layout.placement")

local M = {}

local stack_cards

function M.is_active()
	return stack_cards ~= nil and #stack_cards > 0
end

function M.cards()
	return stack_cards
end

function M.set_cards(cards)
	stack_cards = cards
end

function M.clear()
	stack_cards = nil
end

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

function M.stack_layout()
	local timer = placement_layout.timeline_rect()
	local card_w = G.CARD_W or 1
	local card_h = G.CARD_H or 1.4
	local clearance = math.max(0.45, card_w * 0.30)
	local margin_y = math.max(0.10, card_h * 0.08)
	local room_x = (G.ROOM and G.ROOM.T and G.ROOM.T.x) or 0
	local x = gameplay_left_edge() - clearance - card_w
	local screen_min = room_x - card_w * 2.5
	if x < screen_min then
		x = screen_min
	end
	return {
		x = x,
		y = timer.y + timer.h + margin_y,
		card_w = card_w,
		card_h = card_h,
		step_y = card_h * 0.5,
		clearance = clearance,
	}
end

function M.clears_gameplay_bounds()
	local layout = M.stack_layout()
	local left_edge = gameplay_left_edge()
	return layout.x + layout.card_w + layout.clearance <= left_edge + 0.02
end

function M.target_position(index)
	local layout = M.stack_layout()
	return layout.x, layout.y + (index - 1) * layout.step_y
end

function M.draw_pass()
	if not stack_cards then return end
	for _, card in ipairs(stack_cards) do
		if card and not card.REMOVED then
			love.graphics.push()
			card:translate_container()
			card:draw()
			love.graphics.pop()
		end
	end
end

return M
