--[[ packages/jumbalaya_core/cards/pile_counts.lua - Pure pile size helpers (no G) ]]

local pile_record = require("jumbalaya_core.cards.pile_record")

local M = {}

function M.hand_card_count(hand_cards)
	return pile_record.count(hand_cards)
end

function M.placement_count(placement_cards)
	return pile_record.count(placement_cards)
end

function M.held_count(hand_cards, placement_cards)
	return M.hand_card_count(hand_cards) + M.placement_count(placement_cards)
end

function M.draw_pile_count(draw_pile_cards)
	return draw_pile_cards and #draw_pile_cards or 0
end

return M
