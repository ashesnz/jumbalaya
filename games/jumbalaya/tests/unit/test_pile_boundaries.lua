--[[ tests/unit/test_pile_boundaries.lua - Store piles vs CardPile presentation boundaries ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local audit = require("tests.helpers.pile_boundary_audit")
local piles = require("word_game.model.piles")
local pile_selectors = require("jumbalaya_core.store.selectors.piles")
local Store = require("jumbalaya_core.store")
local word_game = require("word_game")

T.describe("pile boundaries", function()
	mock_env.reset_game()

	T.it("model glue does not import CardPile / cardarea", function()
		local violations = audit.model_cardarea_imports()
		T.assert_equal(#violations, 0, table.concat(violations, ", "))
	end)

	T.it("cardarea package does not import gameplay rules modules", function()
		local violations = audit.cardarea_gameplay_imports()
		T.assert_equal(#violations, 0, table.concat(violations, ", "))
	end)

	T.it("move_card dispatches MOVE_CARD and mirrors pile_id on the live card", function()
		local store = Store.new({
			piles = {
				hand = { { id = 4, ability = { letter = "T" }, pile_id = "hand" } },
				draw = {},
				pattern = {},
				bonus = {},
				discard = {},
			},
		})
		word_game._bind_store(store)
		local card = { letter_card_id = 4, ability = { letter = "T" }, pile_id = "hand" }
		piles.move_card({
			card = card,
			from_pile = "hand",
			to_pile = "pattern",
			slot_index = 2,
		})
		T.assert_equal(card.pile_id, "pattern")
		T.assert_equal(card.slot_index, 2)
		local state = store:get()
		T.assert_equal(#pile_selectors.hand_cards(state), 0)
		local pattern = pile_selectors.pattern_cards(state)
		T.assert_equal(pattern[2].id, 4)
		T.assert_equal(pattern[2].pile_id, "pattern")
	end)
end)
