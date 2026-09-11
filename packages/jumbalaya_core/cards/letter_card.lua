--[[ packages/jumbalaya_core/cards/letter_card.lua - Letter card data helpers (no G, no Card class) ]]

local DictionaryCards = require("jumbalaya_core.dictionary.cards")

local M = {}

function M.tag_ability(card, letter, color)
	card.ability = card.ability or {}
	card.ability.letter = letter
	card.ability.letter_color = color
end

function M.color_from_card(card, opts)
	opts = opts or {}
	if card and card.ability and card.ability.modified == true and opts.modified_color then
		return opts.modified_color
	end
	return DictionaryCards.color_from_card(card)
end

function M.letter_from_card(card)
	return DictionaryCards.letter_from_card(card)
end

function M.compare_for_deck_sort(a, b)
	local la = (a and a.ability and a.ability.letter) or ""
	local lb = (b and b.ability and b.ability.letter) or ""
	if la == lb then
		local ca = (a and a.ability and a.ability.letter_color) or ""
		local cb = (b and b.ability and b.ability.letter_color) or ""
		return ca < cb
	end
	return la < lb
end

function M.sort_deck_cards(cards)
	local out = {}
	for index, card in ipairs(cards or {}) do
		out[index] = card
	end
	table.sort(out, M.compare_for_deck_sort)
	return out
end

function M.is_active_inventory_card(card)
	return card and not card.REMOVED
end

function M.is_jumble_draw_candidate(card)
	return M.is_active_inventory_card(card) and not card.boss_temp and not card.bonus_card
end

function M.returns_to_draw_pile(card)
	return card and not card.boss_temp and not card.bonus_card
end

function M.collect_active_cards(cards)
	local out = {}
	for _, card in ipairs(cards or {}) do
		if M.is_active_inventory_card(card) then
			out[#out + 1] = card
		end
	end
	return out
end

return M
