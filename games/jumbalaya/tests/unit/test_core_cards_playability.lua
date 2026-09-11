--[[ tests/unit/test_core_cards_playability.lua - deck playability helpers without G ]]

local core_env = require("tests.helpers.core_env")
core_env.setup_package_path()

local T = require("tests.framework")
local Playability = require("jumbalaya_core.cards.playability")

T.describe("jumbalaya_core cards playability", function()
	local draw_pile = { id = "draw_pile" }

	T.it("counts owned deck vowels and consonants", function()
		local cards = {
			{ area = draw_pile, ability = { letter = "A" } },
			{ area = draw_pile, ability = { letter = "Z" } },
			{ area = { id = "hand" }, ability = { letter = "E" } },
		}
		local vowels, consonants = Playability.deck_letter_counts(cards, draw_pile)
		T.assert_equal(vowels, 1)
		T.assert_equal(consonants, 1)
	end)

	T.it("treats unowned cards as not in the draw pile", function()
		local card = { area = { id = "hand" }, ability = { letter = "A" } }
		T.assert_false(Playability.deck_owns(card, draw_pile))
	end)
end)
