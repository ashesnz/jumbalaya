--[[ tests/unit/test_core_dictionary_cards.lua - card letter helpers without G ]]

local core_env = require("tests.helpers.core_env")
core_env.setup_package_path()

local T = require("tests.framework")
local Cards = require("jumbalaya_core.dictionary.cards")

T.describe("jumbalaya_core dictionary cards", function()
	T.it("reads letters from ability tables", function()
		T.assert_equal(Cards.letter_from_card({ ability = { letter = "Z" } }), "Z")
	end)

	T.it("reads letters from base rank id without WORD_GAME", function()
		T.assert_equal(Cards.letter_from_card({ base = { id = 1 } }), "A")
		T.assert_equal(Cards.letter_from_id(26), "Z")
	end)

	T.it("builds multiset counts from cards", function()
		local counts = Cards.counts_from_cards({
			{ ability = { letter = "C" } },
			{ ability = { letter = "A" } },
			{ ability = { letter = "T" } },
		})
		T.assert_equal(counts.C, 1)
		T.assert_equal(counts.A, 1)
		T.assert_equal(counts.T, 1)
	end)

	T.it("detects vowels in a hand", function()
		T.assert_true(Cards.hand_has_vowel({ { ability = { letter = "Q" } }, { ability = { letter = "E" } } }))
		T.assert_false(Cards.hand_has_vowel({ { ability = { letter = "Q" } }, { ability = { letter = "Z" } } }))
	end)
end)
