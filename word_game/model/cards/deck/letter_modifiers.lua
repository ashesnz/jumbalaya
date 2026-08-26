-- Per-letter marketplace modifiers for deck cards (A–Z).
return function(context)
	local M = context.module

	M.LETTER_MODIFIERS = {
		A = "Word containing A gets +0.2× multiplier if played within 5 seconds.",
		B = "Word containing B gives +3 bonus points when banked.",
		C = "Increases the puzzle's combo by an additional +0.1×.",
		D = "If a word contains D, its last letter's points are doubled.",
		E = "Gives +1 point.",
		F = "Word containing F gives +1 second.",
		G = "Gives +0.5× multiplier, but only if the word is 5+ letters.",
		H = "5+ letter word containing H gets +5 points.",
		I = "Makes the next word start at +0.2× multiplier.",
		J = "Gives +10 points, but only once per puzzle.",
		K = "Gives +0.2× multiplier.",
		L = "Adds +2 points for every letter beyond 4.",
		M = "Increases the current multiplier by +0.1×.",
		N = "After playing N, the next word gets +0.3×.",
		O = "Gives +2 seconds when the word is played with <15 seconds remaining.",
		P = "Gives +50% points if it is used in a 6+ letter word.",
		Q = "Playing Q automatically attaches U, creating QU.",
		R = "Gives +0.1× for every previous word on the puzzle.",
		S = "Consecutive words containing S gain +2 points each, stacking during the puzzle.",
		T = "Gives +1 second whenever a word containing T is banked.",
		U = "Can substitute for one missing vowel when forming a valid word.",
		V = "Gives +5 points when the word brings you to the stage target.",
		W = "Counts as either a vowel or consonant for pattern validation.",
		X = "Gives +10 points, but only once per stage.",
		Y = "Gives +1 point per second remaining, capped at +10.",
		Z = "Gives +0.5× multiplier when used in a 6+ letter word.",
	}

	function M.modifier_description(letter)
		if type(letter) ~= "string" then return nil end
		return M.LETTER_MODIFIERS[letter:upper()]
	end

	function M.card_letter(card)
		return card and card.ability and card.ability.letter
	end

	function M.is_modified(card)
		return card and card.ability and card.ability.modified == true
	end

	function M.apply_to_card(card)
		if not card or not card.ability then return false end
		if M.is_modified(card) then return false end
		card.ability.modified = true
		card.edition = nil
		return true
	end

	function M.modified_cards_in(cards)
		local out = {}
		for _, card in ipairs(cards or {}) do
			if M.is_modified(card) then
				out[#out + 1] = card
			end
		end
		return out
	end

	function M.has_modified_letter(cards, letter)
		letter = letter and letter:upper()
		for _, card in ipairs(cards or {}) do
			if M.is_modified(card) and M.card_letter(card) == letter then
				return true
			end
		end
		return false
	end

	function M.deck_has_modified_letter(letter)
		letter = letter and letter:upper()
		for _, card in ipairs(G.playing_cards or {}) do
			if not card.REMOVED and M.is_modified(card) and M.card_letter(card) == letter then
				return true
			end
		end
		return false
	end
end
