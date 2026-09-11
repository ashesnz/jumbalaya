--[[ packages/jumbalaya_core/cards/pile_counts.lua - Pure pile size helpers (no G) ]]

local M = {}

function M.hand_card_count(hand_cards)
	return hand_cards and #hand_cards or 0
end

function M.placement_count(placement_cards)
	return placement_cards and #placement_cards or 0
end

function M.held_count(hand_cards, placement_cards)
	return M.hand_card_count(hand_cards) + M.placement_count(placement_cards)
end

function M.draw_pile_count(draw_pile_cards)
	return draw_pile_cards and #draw_pile_cards or 0
end

return M
