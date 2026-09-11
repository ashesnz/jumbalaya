--[[ tests/unit/test_core_cards_deck_config.lua - deck config without G ]]

local core_env = require("tests.helpers.core_env")
core_env.setup_package_path()

local T = require("tests.framework")
local DeckConfig = require("jumbalaya_core.cards.deck_config")

T.describe("jumbalaya_core cards deck config", function()
	T.it("ships the canonical starting letter multiset", function()
		T.assert_equal(#DeckConfig.STARTING_LETTERS, 12)
		T.assert_equal(DeckConfig.STARTING_LETTERS[1], "E")
	end)

	T.it("weights common letters 4x in the trade bag", function()
		local bag = DeckConfig.weighted_letter_bag()
		local counts = {}
		for _, letter in ipairs(bag) do
			counts[letter] = (counts[letter] or 0) + 1
		end
		T.assert_equal(counts.A, 4)
		T.assert_equal(counts.Z, 1)
		T.assert_equal(DeckConfig.pick_weighted_letter(bag, 1), bag[1])
	end)
end)
