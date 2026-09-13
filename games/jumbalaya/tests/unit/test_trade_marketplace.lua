--[[ tests/unit/test_trade_marketplace.lua - Card marketplace offer and deck binding ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("Card marketplace offers (word_game.model.trade)", function()
	mock_env.reset_game()
	local trade = require("word_game.model.trade")
	local deck = require("word_game.model.cards.deck")

	local function vowel_count(letters)
		local count = 0
		for _, item in ipairs(letters) do
			if Dictionary.is_vowel_letter(item.letter) then
				count = count + 1
			end
		end
		return count
	end

	T.it("offers three distinct letters with no duplicates", function()
		for i = 1, 30 do
			local offer = trade.roll_offer()
			T.assert_equal(#offer.add.letters, 3, "Marketplace should offer three cards")
			local seen = {}
			for _, item in ipairs(offer.add.letters) do
				T.assert_nil(seen[item.letter], "Offered letters must be unique")
				seen[item.letter] = true
			end
		end
	end)

	T.it("offers three cards: two random A–Z letters and one vowel", function()
		local saw_vowel = false
		for i = 1, 20 do
			local offer = trade.roll_offer()
			T.assert_equal(#offer.add.letters, 3, "Marketplace should offer three cards")
			T.assert_true(vowel_count(offer.add.letters) >= 1, "At least one offered letter should be a vowel")
			for _, item in ipairs(offer.add.letters) do
				T.assert_true(item.letter >= "A" and item.letter <= "Z", "Letters should be A–Z")
			end
			if vowel_count(offer.add.letters) >= 1 then
				saw_vowel = true
			end
		end
		T.assert_true(saw_vowel, "Rolls should include vowel slots")
	end)

	T.it("greys out remove and modify when the offered letter is not in the deck", function()
		G.letter_inventory = {}
		G.draw_pile = {
			cards = {},
			emplace = function(self, card) self.cards[#self.cards + 1] = card end,
			config = {},
		}
		local offer = trade.roll_offer()
		for _, item in ipairs(offer.add.letters) do
			if not deck.find_deck_card(item.letter) then
				T.assert_nil(item.card, "Offered letters outside the deck should have no bound card")
				T.assert_false(trade.item_in_deck(item), "Deck actions should be unavailable without a deck card")
			end
		end
	end)

	T.it("enables deck actions after the offered letter is added to the deck", function()
		G.letter_inventory = {}
		local cards = {}
		G.draw_pile = {
			cards = cards,
			emplace = function(self, card) self.cards[#self.cards + 1] = card end,
			config = {},
		}
		local create_letter_card = deck.create_letter_card
		deck.create_letter_card = function(letter, color)
			local card = { ability = { letter = letter, letter_color = color }, REMOVED = false }
			G.letter_inventory[#G.letter_inventory + 1] = card
			return card
		end

		local offer = trade.roll_offer()
		local item = offer.add.letters[1]
		local ok = trade.add_letter(item, { cost = 0, defer_used = true })
		deck.create_letter_card = create_letter_card

		T.assert_true(ok, "Adding the marketplace letter should succeed")
		T.assert_true(trade.item_in_deck(item), "Added letters should bind to the deck card")
		trade.sync_offer_cards(offer)
		T.assert_true(trade.item_in_deck(item), "Sync should keep deck bindings current")
	end)

	T.it("reports affordability through can_afford_action", function()
		local trade_ui = require("word_game.ui.trade")
		mock_env.patch_game({ run_state = { tokens = 22, perks = {}, trade_used_this_hand = false } })
		G.RUN = G.RUN or {}
		G.RUN.active = true
		local session_state = { add_cost_bonus = 10 }
		T.assert_true(trade_ui.can_afford_action("add", session_state))
		T.assert_true(trade_ui.can_afford_action("remove", session_state))
		T.assert_false(trade_ui.can_afford_action("modifier", session_state))

		mock_env.mutate_game(function(g) g.run_state.tokens = 2 end)
		T.assert_false(trade_ui.can_afford_action("add", session_state))
		T.assert_false(trade_ui.can_afford_action("remove", session_state))
		T.assert_false(trade_ui.can_afford_action("modifier", session_state))
	end)

	T.it("counts every live copy of a letter in the deck", function()
		G.letter_inventory = {}
		local cards = {}
		G.draw_pile = {
			cards = cards,
			emplace = function(self, card) self.cards[#self.cards + 1] = card end,
			config = {},
		}
		local create_letter_card = deck.create_letter_card
		deck.create_letter_card = function(letter, color)
			local card = { ability = { letter = letter, letter_color = color }, REMOVED = false }
			G.letter_inventory[#G.letter_inventory + 1] = card
			return card
		end
		G.draw_pile:emplace(deck.create_letter_card("E", "red"))
		G.draw_pile:emplace(deck.create_letter_card("E", "black"))
		G.draw_pile:emplace(deck.create_letter_card("A", "red"))
		deck.create_letter_card = create_letter_card

		T.assert_equal(deck.count_letters_in_deck("E"), 2)
		T.assert_equal(deck.count_letters_in_deck("A"), 1)
		T.assert_equal(deck.count_letters_in_deck("Z"), 0)
	end)
end)
