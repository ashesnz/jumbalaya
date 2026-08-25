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
		G.playing_cards = {}
		G.deck = {
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
		G.playing_cards = {}
		local cards = {}
		G.deck = {
			cards = cards,
			emplace = function(self, card) self.cards[#self.cards + 1] = card end,
			config = {},
		}
		local create_letter_card = deck.create_letter_card
		deck.create_letter_card = function(letter, color)
			local card = { ability = { letter = letter, letter_color = color }, REMOVED = false }
			G.playing_cards[#G.playing_cards + 1] = card
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
end)
