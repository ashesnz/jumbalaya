--[[ packages/jumbalaya_core/store/reducers/piles.lua - Pile state reducers (no G) ]]

local pile_record = require("jumbalaya_core.cards.pile_record")

local M = {}

function M.SYNC_PILES(state, action)
	state.piles = action.piles or state.piles or {
		hand = {},
		draw = {},
		pattern = {},
		bonus = {},
		discard = {},
	}
	return state
end

local function append_to_pile(pile, card)
	pile[#pile + 1] = card
	card.slot_index = #pile
end

local function remove_card_from_pile(pile, card_id, sparse_allowed)
	if not pile then return nil end
	if sparse_allowed then
		for i, card in pairs(pile) do
			if type(i) == "number" and card and card.id == card_id then
				local removed = pile[i]
				pile[i] = nil
				return removed
			end
		end
		return nil
	end
	for i, card in ipairs(pile) do
		if card and card.id == card_id then
			return table.remove(pile, i)
		end
	end
	return nil
end

function M.ADD_CARD_TO_PILE(state, action)
	if not action.card or not action.pile_id then return state end
	state.piles = state.piles or { hand = {}, draw = {}, pattern = {}, bonus = {}, discard = {} }
	local pile = state.piles[action.pile_id]
	if pile then
		local card = action.card
		card.pile_id = action.pile_id
		if action.slot_index then
			card.slot_index = action.slot_index
			pile[action.slot_index] = card
		else
			pile[#pile + 1] = card
		end
	end
	return state
end

function M.REMOVE_CARD_FROM_PILE(state, action)
	if not action.card_id or not action.pile_id then return state end
	state.piles = state.piles or {}
	remove_card_from_pile(state.piles[action.pile_id], action.card_id, action.pile_id == "pattern")
	return state
end

function M.MOVE_CARD(state, action)
	local card_id = action.card_id
	local from_pile = action.from_pile
	local to_pile = action.to_pile
	local slot_index = action.slot_index

	if not card_id or not to_pile then return state end
	state.piles = state.piles or { hand = {}, draw = {}, pattern = {}, bonus = {}, discard = {} }

	local found_card = nil
	if from_pile and state.piles[from_pile] then
		found_card = remove_card_from_pile(state.piles[from_pile], card_id, from_pile == "pattern")
	else
		for pile_id, pile in pairs(state.piles) do
			found_card = remove_card_from_pile(pile, card_id, pile_id == "pattern")
			if found_card then break end
		end
	end

	if found_card then
		found_card.pile_id = to_pile
		local dest = state.piles[to_pile]
		if dest then
			if to_pile == "pattern" and slot_index then
				found_card.slot_index = slot_index
				dest[slot_index] = found_card
			else
				found_card.slot_index = nil
				append_to_pile(dest, found_card)
			end
		end
	end

	return state
end

return M
