-- Drafting, cutting, weighted selection, and deck listing.
return function(context)
	local M = context.module
	local LetterPalette = require "word_game.config.visuals.letter_card_palette"
	local common_letters = { A = true, E = true, I = true, O = true, U = true, L = true, N = true, S = true, T = true, R = true }

	M.STARTING_LETTERS = { "E", "E", "A", "A", "I", "O", "T", "S", "R", "Y", "N", "C" }

	function M.shuffle_deck()
		if not G.draw_pile or not G.draw_pile.cards then return end
		local cards = G.draw_pile.cards
		for i = #cards, 2, -1 do
			local j = math.random(1, i)
			cards[i], cards[j] = cards[j], cards[i]
		end
	end

 function M.populate_starting_deck()
 	G.draw_pile.config = G.draw_pile.config or {}
		G.letter_inventory = {}
		G.letter_card_id = 0
		G.draw_pile.cards = {}
		for _, letter in ipairs(M.STARTING_LETTERS) do
			G.draw_pile:emplace(M.create_letter_card(letter, LetterPalette.DEFAULT_FACE_COLOR))
		end
		G.GAME.starting_deck_size = #M.STARTING_LETTERS
		G.draw_pile.config.card_limit = #M.STARTING_LETTERS
		M.shuffle_deck()
 	if G.draw_pile.hard_set_T then G.draw_pile:hard_set_T() end
		M.sync_deck_count_display()
	end

	 function M.draft_letter(letter, color)
	 	G.draw_pile.config = G.draw_pile.config or {}
	 local card = M.create_letter_card(letter, color)
		G.draw_pile:emplace(card)
		G.draw_pile.config.card_limit = (G.draw_pile.config.card_limit or #M.STARTING_LETTERS) + 1
		M.sync_deck_count_display()
		return card
	end

	function M.destroy_card(card)
		if not card then return end
		for _, area in ipairs(M.all_areas()) do
			if area and card.area == area then
				if G.pattern_row and area == G.pattern_row.area then
					G.pattern_row:on_remove_card(card)
				end
				area:remove_card(card)
				break
			end
		end
		for i = #(G.letter_inventory or {}), 1, -1 do
			if G.letter_inventory[i] == card then
				table.remove(G.letter_inventory, i)
				break
			end
		end
		card.REMOVED = true
		if G.draw_pile then
			G.draw_pile.config = G.draw_pile.config or {}
			local total = #(G.letter_inventory or {})
			G.draw_pile.config.card_limit = math.max(total, (G.draw_pile.config.card_limit or 1) - 1)
		end
		if card.remove then
			card:remove()
		end
	end

	function M.cut_card(card)
		M.destroy_card(card)
	end

	function M.common_weighted_letter()
		-- Weight common tier 4× vs the rest so The Trade feels like coverage.
		local bag = {}
		for i = 1, 26 do
			local letter = string.char(string.byte("A") + i - 1)
			local n = common_letters[letter] and 4 or 1
			for _ = 1, n do
				bag[#bag + 1] = letter
			end
		end
		local letter = bag[seeded_random("trade_letter", 1, #bag)]
		local color = (seeded_random("trade_color", 1, 2) == 1) and "red" or "black"
		return letter, color
	end

	function M.list_deck_cards()
		local out = {}
		M.iter_cards(function(card)
			out[#out + 1] = card
		end)
		table.sort(out, function(a, b)
			local la = (a.ability and a.ability.letter) or ""
			local lb = (b.ability and b.ability.letter) or ""
			if la == lb then
				return (a.ability and a.ability.letter_color or "")
					< (b.ability and b.ability.letter_color or "")
			end
			return la < lb
		end)
		return out
	end
end
