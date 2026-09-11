-- Drafting, cutting, weighted selection, and deck listing.
local live_game = require("word_game.model.live_game")

return function(context)
	local M = context.module
	local LetterPalette = require "word_game.config.visuals.letter_card_palette"
	local deck_config = require("jumbalaya_core.cards.deck_config")
	local core_letter_card = require("jumbalaya_core.cards.letter_card")
	local game_access = require("word_game.model.game_access")
	local piles = require("word_game.model.piles")

	M.STARTING_LETTERS = deck_config.STARTING_LETTERS

	function M.shuffle_deck()
		if not live_game().draw_pile or not live_game().draw_pile.cards then return end
		local cards = live_game().draw_pile.cards
		for i = #cards, 2, -1 do
			local j = math.random(1, i)
			cards[i], cards[j] = cards[j], cards[i]
		end
	end

 function M.populate_starting_deck()
 	live_game().draw_pile.config = live_game().draw_pile.config or {}
		live_game().letter_inventory = {}
		live_game().letter_card_id = 0
		live_game().draw_pile.cards = {}
		for _, letter in ipairs(M.STARTING_LETTERS) do
			live_game().draw_pile:emplace(M.create_letter_card(letter, LetterPalette.DEFAULT_FACE_COLOR))
		end
		game_access.patch({ starting_deck_size = #M.STARTING_LETTERS })
		live_game().draw_pile.config.card_limit = #M.STARTING_LETTERS
		M.shuffle_deck()
 	if live_game().draw_pile.hard_set_T then live_game().draw_pile:hard_set_T() end
		piles.sync_hosts_to_store(nil, { "draw" })
		piles.release_static_chrome(nil, { "draw" })
		M.sync_deck_count_display()
	end

	 function M.draft_letter(letter, color)
	 	live_game().draw_pile.config = live_game().draw_pile.config or {}
	 local card = M.create_letter_card(letter, color)
		live_game().draw_pile:emplace(card)
	 live_game().draw_pile.config.card_limit = (live_game().draw_pile.config.card_limit or #M.STARTING_LETTERS) + 1
		if M.commit_pile_hosts then
			M.commit_pile_hosts({ "draw" })
		else
			M.sync_deck_count_display()
		end
		return card
	end

	function M.destroy_card(card)
		if not card then return end
		for _, area in ipairs(M.all_areas()) do
			if area and card.area == area then
				if live_game().pattern_row and area == live_game().pattern_row.area then
					live_game().pattern_row:on_remove_card(card)
				end
				area:remove_card(card)
				break
			end
		end
		for i = #(live_game().letter_inventory or {}), 1, -1 do
			if live_game().letter_inventory[i] == card then
				table.remove(live_game().letter_inventory, i)
				break
			end
		end
		card.REMOVED = true
		if live_game().draw_pile then
			live_game().draw_pile.config = live_game().draw_pile.config or {}
			local total = #(live_game().letter_inventory or {})
			live_game().draw_pile.config.card_limit = math.max(total, (live_game().draw_pile.config.card_limit or 1) - 1)
		end
		if card.remove then
			card:remove()
		end
	end

	function M.cut_card(card)
		M.destroy_card(card)
	end

	function M.common_weighted_letter()
		local bag = deck_config.weighted_letter_bag()
		local letter = deck_config.pick_weighted_letter(bag, seeded_random("trade_letter", 1, #bag))
		local color = (seeded_random("trade_color", 1, 2) == 1) and "red" or "black"
		return letter, color
	end

	function M.list_deck_cards()
		local out = {}
		M.iter_cards(function(card)
			out[#out + 1] = card
		end)
		return core_letter_card.sort_deck_cards(out)
	end
end
