--[[ tests/unit/test_phase5_2_table_areas.lua - Phase 5.2 TableAreas selectors and save aliases test ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local TableAreas = require("word_game.model.table_areas")
local Store = require("jumbalaya_core.store")
local LetterCard = require("jumbalaya_core.cards.letter_card")

T.describe("Phase 5.2 TableAreas Selectors & Save Aliases", function()
	mock_env.reset_game()

	T.it("resolves save keys correctly using SAVE_ALIASES", function()
		T.assert_equal(TableAreas.resolve_save_key("hand"), "dealt_letters")
		T.assert_equal(TableAreas.resolve_save_key("dealt_letters"), "dealt_letters")
		T.assert_equal(TableAreas.resolve_save_key("deck"), "draw_pile")
		T.assert_equal(TableAreas.resolve_save_key("draw_pile"), "draw_pile")
		T.assert_equal(TableAreas.resolve_save_key("discard"), "recycle_stash")
		T.assert_equal(TableAreas.resolve_save_key("recycle_stash"), "recycle_stash")
		T.assert_equal(TableAreas.resolve_save_key("placement_table"), "pattern_row")
		T.assert_equal(TableAreas.resolve_save_key("unknown_key"), "unknown_key")
	end)

	T.it("selects pile cards from store state", function()
		local store = Store.new()
		local card = LetterCard.new(10, "A", "white", "hand", 1)
		store:dispatch({ type = "ADD_CARD_TO_PILE", pile_id = "hand", card = card, slot_index = 1 })
		local state = store:get()

		local hand_cards = TableAreas.hand_cards(state)
		T.assert_equal(#hand_cards, 1)
		T.assert_equal(hand_cards[1].id, 10)
		T.assert_equal(hand_cards[1].letter, "A")

		local draw_cards = TableAreas.draw_cards(state)
		T.assert_equal(#draw_cards, 0)
	end)

	T.it("selects pile cards via WORD_GAME.store when state parameter is omitted", function()
		local store = Store.new()
		require("word_game")._bind_store(store)
		local card = LetterCard.new(20, "B", "red", "draw", 1)
		store:dispatch({ type = "ADD_CARD_TO_PILE", pile_id = "draw", card = card })

		local draw_cards = TableAreas.draw_cards()
		T.assert_equal(#draw_cards, 1)
		T.assert_equal(draw_cards[1].id, 20)

	end)
end)
