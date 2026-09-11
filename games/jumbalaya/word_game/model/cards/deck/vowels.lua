-- Vowel guarantees and requested-letter hand adjustments.
local live_game = require("word_game.model.live_game")

return function(context)
	local M = context.module
	local hand_size_cfg = require("word_game.model.hand_size")
	local card_letter = context.card_letter
	local deck_owns = context.deck_owns
	local fly_from_deck_to_hand = context.fly_from_deck_to_hand
	local placement_cards = context.placement_cards

	local function cards_have_vowel(cards)
		for _, card in ipairs(cards or {}) do
			if Dictionary.is_vowel_letter(card_letter(card)) then
				return true
			end
		end
		return false
	end

	function M.held_has_vowel()
		return cards_have_vowel(live_game().dealt_letters and live_game().dealt_letters.cards) or cards_have_vowel(placement_cards())
	end

	local function needs_vowel()
		return not M.held_has_vowel()
	end

	context.needs_vowel = needs_vowel

	local function find_consonant(cards)
		for _, card in ipairs(cards or {}) do
			if card and not Dictionary.is_vowel_letter(card_letter(card)) then
				return card
			end
		end
	end

	local piles = require("word_game.model.piles")

	local function take_letter_from_deck(prefer_vowel)
		if not live_game().draw_pile then return nil end
		if #live_game().draw_pile.cards == 0 then
			piles.hydrate_hosts_from_store({ "draw" })
		end
		if #live_game().draw_pile.cards == 0 then return nil end

		local function accept(card)
			if not card then return nil end
			M.reveal_in_hand(card)
			if M.is_letter_card(card) then
				return card
			end
			if card.remove then card:remove() end
			return nil
		end

		while #live_game().draw_pile.cards > 0 do
			local top = table.remove(live_game().draw_pile.cards)
			if top and not deck_owns(top) then
				if top.remove_from_area then top:remove_from_area() end
			else
				if top and top.remove_from_area then top:remove_from_area() end
				local taken = accept(top)
				if taken then return taken end
			end
		end
		return nil
	end

	context.take_letter_from_deck = take_letter_from_deck

	function M.deck_has_vowel()
		for _, card in ipairs(live_game().draw_pile and live_game().draw_pile.cards or {}) do
			if not card.area or card.area == live_game().draw_pile then
				local letter = Dictionary and Dictionary.letter_from_card(card)
				if Dictionary.is_vowel_letter(letter) then
					return true
				end
			end
		end
		return false
	end

	local function give_vowel_to_hand(card)
		return fly_from_deck_to_hand(card)
	end

	function M.ensure_vowel_in_hand()
		if not live_game().dealt_letters or M.held_has_vowel() then return false end
		if not M.deck_has_vowel() then return false end

		local target = hand_size_cfg.get()
		if M.held_count() < target then
			local card = take_letter_from_deck(true)
			if card then
				give_vowel_to_hand(card)
				if M.held_has_vowel() then return true end
			end
		end
		if M.held_has_vowel() then return true end

		local swap_card = find_consonant(live_game().dealt_letters.cards) or find_consonant(placement_cards())
		local vowel_card = take_letter_from_deck(true)
		if not vowel_card or not Dictionary.is_vowel_letter(card_letter(vowel_card)) then
			if vowel_card then
				live_game().draw_pile:emplace(vowel_card)
			end
			return false
		end
		if not swap_card then
			live_game().draw_pile:emplace(vowel_card)
			return false
		end
		if swap_card.area then
			swap_card.area:remove_card(swap_card)
		end
		live_game().draw_pile:emplace(swap_card)
		return give_vowel_to_hand(vowel_card)
	end

	function M.ensure_letters_in_hand(letters)
		if not letters or not live_game().dealt_letters or not live_game().draw_pile or not Dictionary then return end

		local function in_hand(letter)
			for _, card in ipairs(live_game().dealt_letters.cards) do
				if Dictionary.letter_from_card(card) == letter then
					return true
				end
			end
			return false
		end

		local needed = {}
		for _, letter in ipairs(letters) do
			needed[letter] = true
		end

		for _, letter in ipairs(letters) do
			if not in_hand(letter) then
				local from_deck = nil
				for _, deck_card in ipairs(live_game().draw_pile.cards) do
					if deck_owns(deck_card) and Dictionary.letter_from_card(deck_card) == letter then
						from_deck = deck_card
						break
					end
				end
				local swap_card = nil
				for _, hand_card in ipairs(live_game().dealt_letters.cards) do
					if hand_card.area == live_game().dealt_letters then
						local have = Dictionary.letter_from_card(hand_card)
						if not needed[have] then
							swap_card = hand_card
							break
						end
					end
				end
				if from_deck and swap_card then
					live_game().dealt_letters:remove_card(swap_card)
					live_game().draw_pile:remove_card(from_deck)
					fly_from_deck_to_hand(from_deck)
					live_game().draw_pile:emplace(swap_card)
				end
			end
		end

		if live_game().dealt_letters then
			live_game().dealt_letters:set_ranks()
			live_game().dealt_letters:relayout()
		end
	end

	function M.find_deck_card(letter)
		if not letter then return nil end
		for _, card in ipairs(M.list_deck_cards()) do
			if card and not card.REMOVED and card_letter(card) == letter then
				return card
			end
		end
		return nil
	end

	function M.count_letters_in_deck(letter)
		if not letter then return 0 end
		local count = 0
		for _, card in ipairs(M.list_deck_cards()) do
			if card and not card.REMOVED and card_letter(card) == letter then
				count = count + 1
			end
		end
		return count
	end

	local function random_index(key, min, max)
		if type(seeded_random) == "function" then
			return seeded_random(key, min, max)
		end
		return math.random(min, max)
	end

	function M.random_vowel_letter(key)
		local vowels = { "A", "E", "I", "O", "U" }
		return vowels[random_index(key or "market_vowel", 1, #vowels)]
	end

	function M.random_letter(key)
		return M.letter_from_id(random_index(key or "market_letter", 1, 26))
	end

	function M.random_letter_color(key)
		return random_index(key or "market_color", 1, 2) == 1 and "red" or "black"
	end
end
