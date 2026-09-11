--[[ packages/jumbalaya_core/store/reducers/piles.lua - Pile state reducers (no G) ]]

local M = {}

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
	local pile = state.piles[action.pile_id]
	if pile then
		for i, card in ipairs(pile) do
			if card.id == action.card_id then
				table.remove(pile, i)
				break
			end
		end
	end
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
		for i, card in ipairs(state.piles[from_pile]) do
			if card.id == card_id then
				found_card = table.remove(state.piles[from_pile], i)
				break
			end
		end
	else
		for pid, pile in pairs(state.piles) do
			for i, card in ipairs(pile) do
				if card.id == card_id then
					found_card = table.remove(pile, i)
					break
				end
			end
			if found_card then break end
		end
	end

	if found_card then
		found_card.pile_id = to_pile
		found_card.slot_index = slot_index
		local dest = state.piles[to_pile]
		if dest then
			if slot_index then
				dest[slot_index] = found_card
			else
				dest[#dest + 1] = found_card
			end
		end
	end

	return state
end

return M
