--[[ packages/jumbalaya_core/cards/playability.lua - Deck playability helpers (no G) ]]

local DictionaryCards = require("jumbalaya_core.dictionary.cards")

local M = {}

function M.deck_owns(card, draw_pile)
	return card and (not card.area or card.area == draw_pile)
end

function M.swap_priority(card)
	local letter = DictionaryCards.letter_from_card(card)
	if not letter then return 0 end
	local letter_index = card and card.base and card.base.letter_index or 0
	if DictionaryCards.is_vowel_letter(letter) then
		return 50 + letter_index
	end
	return letter_index
end

function M.deck_letter_counts(cards, draw_pile)
	local vowels = 0
	local consonants = 0
	for _, card in ipairs(cards or {}) do
		if M.deck_owns(card, draw_pile) then
			local letter = DictionaryCards.letter_from_card(card)
			if letter then
				if DictionaryCards.is_vowel_letter(letter) then
					vowels = vowels + 1
				else
					consonants = consonants + 1
				end
			end
		end
	end
	return vowels, consonants
end

function M.trial_letter_swap(base_counts, remove_letter, add_letter)
	local trial = {}
	for letter, count in pairs(base_counts or {}) do
		trial[letter] = count
	end
	if remove_letter then
		trial[remove_letter] = (trial[remove_letter] or 0) - 1
		if trial[remove_letter] <= 0 then
			trial[remove_letter] = nil
		end
	end
	if add_letter then
		trial[add_letter] = (trial[add_letter] or 0) + 1
	end
	return trial
end

return M
