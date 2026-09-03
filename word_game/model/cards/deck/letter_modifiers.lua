-- Per-letter marketplace modifiers for deck cards (A–Z).
return function(context)
	local M = context.module
	local LetterPalette = require "word_game.config.letter_card_palette"

	local function modifier_entry(description, ui_text)
		return { description = description, ui_text = ui_text }
	end

	M.LETTER_MODIFIERS = {
		A = modifier_entry("+0.2× multiplier", "+0.2×"),
		B = modifier_entry("+3 bonus points when played, 0.5x if played with Y.", "+3 points"),
		C = modifier_entry("Increases the puzzle's combo by an additional +0.1×.", "+0.1× combo"),
		D = modifier_entry("If a word ends with D - 2x multi.", "+1 point"),
		E = modifier_entry("Gives +1 point.", "+1 point"),
		F = modifier_entry("Gain +1 second.", "+1 sec"),
		G = modifier_entry("+0.2× multiplier, 0.5x if 2 G's", "+0.5×"),
		H = modifier_entry("5+ letter word gain +5 points.", "+5 points"),
		I = modifier_entry("Gives +1 point.", "+1 point"),
		J = modifier_entry("Playing J automatically attaches U, creating JU", "+10 once"),
		K = modifier_entry("Gives +0.2× multiplier.", "+0.2×"),
		L = modifier_entry("Adds +4 points for 4+ letter word.", "+2 per letter"),
		M = modifier_entry("Increases the current multiplier by +0.1×.", "+0.1×"),
		N = modifier_entry("After playing N, the next word gets +0.3×.", "+0.3× next"),
		O = modifier_entry("+0.2× multiplier", "+0.2×"),
		P = modifier_entry("Gives +50% points if it is used in a 6+ letter word.", "+50% pts"),
		Q = modifier_entry("Playing Q automatically attaches U, creating QU.", "QU attach"),
		R = modifier_entry("Gives +0.1× for every previous word on the puzzle.", "+0.1× per word"),
		S = modifier_entry("Consecutive words containing S gain +2 points each, stacking during the puzzle.", "+2 streak"),
		T = modifier_entry("Gives +1 second whenever a word containing T is banked.", "+1 sec"),
		U = modifier_entry("Gives +1 point.", "+1 point"),
		V = modifier_entry("Gives +5 points when the word brings you to the stage target.", "+5 target"),
		W = modifier_entry("Counts as either a vowel or consonant for pattern validation.", "Flex letter"),
		X = modifier_entry("Gives +10 points, but only once per stage.", "+10 once"),
		Y = modifier_entry("Gives +1 point per second remaining, capped at +10.", "+1/sec"),
		Z = modifier_entry("Gives +0.5× multiplier when used in a 6+ letter word.", "+0.5×"),
	}

	local function modifier_entry_for(letter)
		if type(letter) ~= "string" then return nil end
		return M.LETTER_MODIFIERS[letter:upper()]
	end

	function M.modifier_description(letter)
		local entry = modifier_entry_for(letter)
		return entry and entry.description
	end

	function M.modifier_ui_text(letter)
		local entry = modifier_entry_for(letter)
		return entry and entry.ui_text
	end

	function M.card_letter(card)
		return card and card.ability and card.ability.letter
	end

	function M.is_modified(card)
		return card and card.ability and card.ability.modified == true
	end

	local function sync_modified_face(card)
		local letter = M.card_letter(card)
		if not letter then return end
		local color = LetterPalette.MODIFIED_FACE_COLOR
		M.tag_card(card, letter, color)
		local front = M.front(letter, color)
		if front and card.apply_face then
			card:apply_face(front, false)
		elseif front and card.set_sprites then
			card:set_sprites(card.config and card.config.center, front)
		end
	end

	function M.apply_to_card(card)
		if not card or not card.ability then return false end
		if M.is_modified(card) then return false end
		card.ability.modified = true
		card.edition = nil
		sync_modified_face(card)
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
