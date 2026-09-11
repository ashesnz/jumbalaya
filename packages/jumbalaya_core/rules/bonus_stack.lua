--[[ packages/jumbalaya_core/rules/bonus_stack.lua - Bonus gutter scoring (no G) ]]

local M = {}

M.BONUS_POINTS = 10

function M.is_bonus_card(card)
	return card and card.bonus_card
end

function M.bonus_points_for(used_cards)
	local total = 0
	for _, card in ipairs(used_cards or {}) do
		if M.is_bonus_card(card) then
			total = total + M.BONUS_POINTS
		end
	end
	return total
end

return M
