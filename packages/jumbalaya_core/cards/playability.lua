--[[ packages/jumbalaya_core/cards/playability.lua - Deck playability helpers (no G) ]]

local DictionaryCards = require("jumbalaya_core.dictionary.cards")

local M = {}

function M.deck_owns(card, draw_pile)
	return card and (not card.area or card.area == draw_pile)
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

return M
