--[[ tests/unit/test_trade_marketplace_offer.lua - Marketplace offer roll ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

local VOWELS = { A = true, E = true, I = true, O = true, U = true }

T.describe("trade marketplace offer", function()
	T.it("rolls three unique letters with exactly one vowel and two consonants", function()
		mock_env.reset_game()
		mock_env.patch_game({
			run_state = { tokens = 100, perks = {}, trade_used_this_hand = false },
			seed_streams = { seed = "market_test", key = 1 },
		})
		local trade = require("word_game.model.trade")
		local offer = trade.roll_offer()
		local letters = offer.add.letters
		T.assert_equal(#letters, 3)

		local vowel_count = 0
		local consonant_count = 0
		local seen = {}
		for _, item in ipairs(letters) do
			T.assert_not_nil(item.letter)
			T.assert_false(seen[item.letter], "letters should be unique: " .. item.letter)
			seen[item.letter] = true
			if VOWELS[item.letter] then
				vowel_count = vowel_count + 1
			else
				consonant_count = consonant_count + 1
			end
		end
		T.assert_equal(vowel_count, 1)
		T.assert_equal(consonant_count, 2)
	end)

	T.it("greys remove when the letter is not in the deck", function()
		mock_env.reset_game()
		local trade = require("word_game.model.trade")
		local item = { letter = "Q", card = nil }
		T.assert_false(trade.can_remove(item))
		T.assert_false(trade.item_in_deck(item))
	end)
end)
