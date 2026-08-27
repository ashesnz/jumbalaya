--[[ word_game/ui/boss_word_stack.lua - Boss word success card stack display ]]

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

function M.stack_layout()
	local felt = require("word_game.ui.layout.felt")
	local layout = require("word_game.ui.layout.placement")
	local col = felt.play_column()
	local timer = layout.timeline_rect()
	local card_w = G.CARD_W or 1
	local card_h = G.CARD_H or 1.4
	local margin_x = math.max(0.10, (G.TILE_W or 20) * 0.01)
	local margin_y = math.max(0.10, card_h * 0.08)
	return {
		x = col.x + margin_x,
		y = timer.y + timer.h + margin_y,
		card_w = card_w,
		card_h = card_h,
		step_y = card_h * 0.5,
	}
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
