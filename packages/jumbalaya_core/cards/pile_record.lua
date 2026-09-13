--[[ packages/jumbalaya_core/cards/pile_record.lua - Plain pile card records (no G, no Card class) ]]

local M = {}

function M.id(card_or_record)
	if not card_or_record then return nil end
	return card_or_record.letter_card_id or card_or_record.id
end

function M.copy_ability(ability)
	if not ability then return {} end
	local out = {}
	for k, v in pairs(ability) do
		out[k] = v
	end
	return out
end

--- Serialize a live card (or existing record) into a store-safe PileCard table.
function M.from_live_card(card, pile_id, slot_index)
	if not card then return nil end
	local id = M.id(card)
	if not id then return nil end
	if slot_index == nil then
		slot_index = card.slot_index
	end
	return {
		id = id,
		pile_id = pile_id,
		slot_index = slot_index,
		ability = M.copy_ability(card.ability),
	}
end

--- True when the value looks like a plain pile record, not a live Card instance.
function M.is_record(value)
	if type(value) ~= "table" then return false end
	if value.T or value.set_card_area or value.remove_from_area then
		return false
	end
	return M.id(value) ~= nil
end

--- Count cards in a pile table (dense or sparse slot-indexed pattern piles).
function M.count(pile)
	if not pile then return 0 end
	local max_index, count = 0, 0
	for k, v in pairs(pile) do
		if type(k) == "number" and v then
			count = count + 1
			if k > max_index then max_index = k end
		end
	end
	if max_index > 0 and max_index == count then
		return max_index
	end
	return count
end

return M
