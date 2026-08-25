--[[
	word_game.board/config.lua - Tunable constants for the placement row.
]]

local M = {
	-- Fallback if G.HAND_CARD_SPACING is unset. Played cards use the hand's
	-- step so 1–7 letters keep the same overlap instead of stretching.
	PLACEMENT_CARD_SPACING = 0.78,
	-- Extra padding on each side of the drop row beyond the tight card cluster.
	ROW_EDGE_PADDING = 0.3,
	DEFAULT_CARD_LIMIT = 7,
	CORNER_RADIUS = 8,
	-- Anchor row within green felt (fraction of felt height from top edge).
	ANCHOR_PAD_Y_FRAC = 0.078,
	LOCK_SHIMMER_DURATION = 0.5,
	-- Pixels outside the placed card edge for the lock shimmer outline.
	OUTLINE_PAD = 5,
	-- Boss row: gap between adjacent card edges as a fraction of card width.
	BOSS_SLOT_GAP_FRAC = 0.14,
}

function M.boss_slot_spacing()
	return 1.0 + M.BOSS_SLOT_GAP_FRAC
end

function M.card_spacing()
	return (G and G.HAND_CARD_SPACING) or M.PLACEMENT_CARD_SPACING
end

function M.row_width_for_slots(slots)
	return 1 + math.max(slots - 1, 0) * M.card_spacing() + 2 * M.ROW_EDGE_PADDING
end

function M.placed_cards_width(card_w, count)
	if count <= 1 then return card_w end
	return card_w + (count - 1) * card_w * M.card_spacing()
end

return M
