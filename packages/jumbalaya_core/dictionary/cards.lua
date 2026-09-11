--[[ packages/jumbalaya_core/dictionary/cards.lua - Card letter extraction (no G, no WORD_GAME) ]]

local M = {}

function M.letter_from_id(rank_id)
	if type(rank_id) == "number" and rank_id >= 1 and rank_id <= 26 then
		return string.char(64 + rank_id)
	end
	return nil
end

function M.letter_from_card(card)
	if card and card.ability and card.ability.letter then
		return card.ability.letter
	end
	if card and card.config and card.config.card and card.config.card.letter then
		return card.config.card.letter
	end
	if not card or not card.base then return nil end
	local value = card.base.value
	if type(value) == "string" and #value == 1 then
		return value:upper()
	end
	local id = card.base.id
	if not id then return nil end
	return M.letter_from_id(id)
end

function M.color_from_card(card)
	if card and card.ability and card.ability.letter_color then
		return card.ability.letter_color
	end
	if card and card.config and card.config.card and card.config.card.color then
		return card.config.card.color
	end
	if card and card.base and card.base.color then
		return card.base.color
	end
	return "black"
end

function M.counts_from_cards(cards)
	local counts = {}
	for _, card in ipairs(cards or {}) do
		local letter = M.letter_from_card(card)
		if letter then
			counts[letter] = (counts[letter] or 0) + 1
		end
	end
	return counts
end

function M.word_from_cards(cards)
	local parts = {}
	for _, card in ipairs(cards or {}) do
		local letter = M.letter_from_card(card)
		if letter then
			parts[#parts + 1] = letter
		end
	end
	return table.concat(parts)
end

function M.is_vowel_letter(letter)
	return letter == "A" or letter == "E" or letter == "I" or letter == "O" or letter == "U"
end

function M.hand_has_vowel(cards)
	for _, card in ipairs(cards or {}) do
		if M.is_vowel_letter(M.letter_from_card(card)) then
			return true
		end
	end
	return false
end

return M
