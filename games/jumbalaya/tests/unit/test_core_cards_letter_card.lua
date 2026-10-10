--[[ tests/unit/test_core_cards_letter_card.lua - letter card data helpers without G ]]

local core_env = require("tests.helpers.core_env")
core_env.setup_package_path()

local T = require("tests.framework")
local LetterCard = require("jumbalaya_core.cards.letter_card")

T.describe("jumbalaya_core cards letter card", function()
	T.it("builds letter ability without center/companion fields", function()
		local ability = LetterCard.ability_from_face({ letter = "C", color = "red" }, { bonus = 2 })
		T.assert_equal(ability.letter, "C")
		T.assert_equal(ability.letter_color, "red")
		T.assert_equal(ability.set, "Default")
		T.assert_equal(ability.bonus, 2)
		T.assert_nil(ability.effect)
		T.assert_nil(ability.order)
	end)

	T.it("maps letters to A=1 sort indexes", function()
		T.assert_equal(LetterCard.letter_index("A"), 1)
		T.assert_equal(LetterCard.letter_index("Z"), 26)
		T.assert_equal(LetterCard.color_tiebreak("gold"), 0.04)
	end)

	T.it("tags ability tables on plain card data", function()
		local card = {}
		LetterCard.tag_ability(card, "E", "red")
		T.assert_equal(card.ability.letter, "E")
		T.assert_equal(card.ability.letter_color, "red")
	end)

	T.it("prefers modified face color when flagged", function()
		local card = { ability = { modified = true, letter_color = "red" } }
		T.assert_equal(LetterCard.color_from_card(card, { modified_color = "modified" }), "modified")
		T.assert_equal(LetterCard.color_from_card(card, {}), "red")
	end)

	T.it("sorts deck cards by letter then color", function()
		local sorted = LetterCard.sort_deck_cards({
			{ ability = { letter = "B", letter_color = "red" } },
			{ ability = { letter = "A", letter_color = "black" } },
			{ ability = { letter = "A", letter_color = "red" } },
		})
		T.assert_equal(sorted[1].ability.letter, "A")
		T.assert_equal(sorted[1].ability.letter_color, "black")
		T.assert_equal(sorted[3].ability.letter, "B")
	end)

	T.it("filters jumble draw candidates and return-to-deck cards", function()
		T.assert_true(LetterCard.is_jumble_draw_candidate({ ability = { letter = "A" } }))
		T.assert_false(LetterCard.is_jumble_draw_candidate({ REMOVED = true }))
		T.assert_false(LetterCard.is_jumble_draw_candidate({ bonus_card = true }))
		T.assert_false(LetterCard.returns_to_draw_pile({ boss_temp = true }))
		T.assert_true(LetterCard.returns_to_draw_pile({ ability = { letter = "Z" } }))
	end)
end)
