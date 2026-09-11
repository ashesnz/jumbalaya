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

	T.it("prioritizes vowels for swap rerolls at equal letter index", function()
		local vowel = { ability = { letter = "A" }, base = { letter_index = 5 } }
		local consonant = { ability = { letter = "Z" }, base = { letter_index = 5 } }
		T.assert_true(Playability.swap_priority(vowel) > Playability.swap_priority(consonant))
	end)

	T.it("builds trial letter multisets for swap checks", function()
		local trial = Playability.trial_letter_swap({ C = 1, A = 1 }, "A", "T")
		T.assert_equal(trial.C, 1)
		T.assert_nil(trial.A)
		T.assert_equal(trial.T, 1)
	end)
end)
