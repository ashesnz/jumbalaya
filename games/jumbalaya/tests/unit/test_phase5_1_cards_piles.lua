--[[ tests/unit/test_phase5_1_cards_piles.lua - Phase 5.1 Card data, Pile store, and Engine Views tests ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local LetterCard = require("jumbalaya_core.cards.letter_card")
local Store = require("jumbalaya_core.store")
local Engine = require("jumbalaya-engine")

T.describe("Phase 5.1 Card Data, Pile Store & Views", function()
	mock_env.reset_game()

	T.it("creates LetterCard data via constructor", function()
		local card = LetterCard.new(101, "A", "white", "hand", 1, { bonus_card = true })
		T.assert_equal(card.id, 101)
		T.assert_equal(card.letter, "A")
		T.assert_equal(card.color_key, "white")
		T.assert_equal(card.pile_id, "hand")
		T.assert_equal(card.slot_index, 1)
		T.assert_true(card.bonus_card)
	end)

	T.it("manages pile state and dispatches pile actions in store", function()
		local store = Store.new()
		local state = store:get()
		T.assert_not_nil(state.piles)
		T.assert_not_nil(state.piles.hand)

		local card1 = LetterCard.new(1, "E", "red", "hand", 1)
		store:dispatch({ type = "ADD_CARD_TO_PILE", pile_id = "hand", card = card1, slot_index = 1 })
		T.assert_equal(#state.piles.hand, 1)
		T.assert_equal(state.piles.hand[1].id, 1)

		-- Move card to pattern pile
		store:dispatch({ type = "MOVE_CARD", card_id = 1, from_pile = "hand", to_pile = "pattern", slot_index = 1 })
		T.assert_equal(#state.piles.hand, 0)
		T.assert_equal(#state.piles.pattern, 1)
		T.assert_equal(state.piles.pattern[1].pile_id, "pattern")

		-- Remove card from pile
		store:dispatch({ type = "REMOVE_CARD_FROM_PILE", pile_id = "pattern", card_id = 1 })
		T.assert_equal(#state.piles.pattern, 0)
	end)

	T.it("renders LetterCardView and PileView via Renderer", function()
		local card = LetterCard.new(2, "S", "blue", "hand", 1)
		local card_view = Engine.Views.LetterCardView.new(card, { x = 0, y = 0, w = 1, h = 1 })

		local called = false
		local mock_adapter = {
			draw_card = function(view, rect)
				called = true
				T.assert_equal(view.card.id, 2)
			end
		}
		local renderer = Engine.Renderer.new(mock_adapter)
		card_view:draw(renderer)
		T.assert_true(called)

		-- Test PileView
		local pile_view = Engine.Views.PileView.new("hand", { card }, { x = 0, y = 0, w = 5, h = 1, card_w = 1 })
		local pile_called = false
		local mock_pile_adapter = {
			draw_card = function(view, rect)
				pile_called = true
			end
		}
		local pile_renderer = Engine.Renderer.new(mock_pile_adapter)
		pile_view:draw(pile_renderer)
		T.assert_true(pile_called)
	end)
end)
