--[[ tests/unit/test_phase5_pile_sync.lua - Phase 5 pile dual-write bridge test ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local pile_sync = require("bridge.pile_sync")
local Store = require("jumbalaya_core.store")
local pile_selectors = require("jumbalaya_core.store.selectors.piles")
local word_game = require("word_game")

T.describe("Phase 5 Pile Sync Bridge", function()
	mock_env.reset_game()

	T.it("snapshots live CardArea cards into store piles", function()
		local store = Store.new()
		word_game._bind_store(store)

		G.dealt_letters = {
			cards = {
				{ letter_card_id = 1, ability = { letter = "A" }, REMOVED = nil },
				{ letter_card_id = 2, ability = { letter = "B" }, REMOVED = nil },
			},
		}
		G.draw_pile = {
			cards = {
				{ letter_card_id = 3, ability = { letter = "C" }, REMOVED = nil },
			},
		}
		G.recycle_stash = { cards = {} }
		G.pattern_row = { area = { cards = {} } }

		pile_sync.sync_areas_to_store(store)
		local state = store:get()
		T.assert_equal(#pile_selectors.hand_cards(state), 2)
		T.assert_equal(#pile_selectors.draw_cards(state), 1)
		T.assert_equal(state.piles.hand[1].id, 1)
		T.assert_equal(state.piles.hand[1].pile_id, "hand")

	end)

	T.it("chrome_release_enabled stays off until store renderer draws live cards", function()
		G.STATE = G.STATES.TABLE_BOARD
		T.assert_false(pile_sync.chrome_release_enabled())

		local Engine = require("jumbalaya-engine")
		local views_install = require("word_game.ui.views.install")
		local store = Store.new()
		word_game._bind_store(store)
		views_install.install_table_board(Engine.Context.new({ store = store }))
		T.assert_false(pile_sync.chrome_release_enabled())
		views_install.reset()
		T.assert_false(pile_sync.chrome_release_enabled())
	end)

	T.it("ensure_legacy_piles_from_store rebuilds empty CardAreas from store", function()
		local store = Store.new({
			piles = {
				hand = {
					{ id = 7, letter_card_id = 7, ability = { letter = "M" }, pile_id = "hand", slot_index = 1 },
				},
				draw = {},
				pattern = {},
				bonus = {},
				discard = {},
			},
		})
		word_game._bind_store(store)

		local card = { letter_card_id = 7, ability = { letter = "M" }, REMOVED = nil }
		G.letter_inventory = { card }
		G.dealt_letters = { cards = {}, set_ranks = function() end, relayout = function() end }
		G.draw_pile = { cards = {} }
		G.recycle_stash = { cards = {} }
		G.pattern_row = { area = { cards = {} } }

		pile_sync.ensure_legacy_piles_from_store(store)
		T.assert_equal(#G.dealt_letters.cards, 1)
		T.assert_equal(G.dealt_letters.cards[1], card)
	end)

	T.it("release_static_chrome snapshots then clears resting CardArea cards", function()
		local store = Store.new({
			piles = { hand = {}, draw = {}, pattern = {}, bonus = {}, discard = {} },
		})
		word_game._bind_store(store)

		local resting = { letter_card_id = 1, ability = { letter = "A" }, REMOVED = nil }
		local dragging = { letter_card_id = 2, ability = { letter = "B" }, REMOVED = nil }
		G.dealt_letters = { cards = { resting, dragging } }
		G.draw_pile = { cards = {} }
		G.recycle_stash = { cards = {} }
		G.pattern_row = { area = { cards = {} } }
		G.INPUT = { dragging = { target = dragging }, focused = { target = nil } }

		pile_sync.release_static_chrome(store, { "hand" })
		local state = store:get()
		T.assert_equal(#pile_selectors.hand_cards(state), 2)
		T.assert_equal(#G.dealt_letters.cards, 1)
		T.assert_equal(G.dealt_letters.cards[1], dragging)
	end)

	T.it("sync_store_to_areas rebuilds CardArea from store piles", function()
		local store = Store.new({
			piles = {
				hand = {
					{ id = 5, letter_card_id = 5, ability = { letter = "Q" }, pile_id = "hand", slot_index = 1 },
				},
				draw = {},
				pattern = {},
				bonus = {},
				discard = {},
			},
		})
		word_game._bind_store(store)

		local card = { letter_card_id = 5, ability = { letter = "Q" }, REMOVED = nil }
		G.letter_inventory = { card }
		G.dealt_letters = { cards = {}, set_ranks = function() end, relayout = function() end }
		G.draw_pile = { cards = {} }
		G.recycle_stash = { cards = {} }
		G.pattern_row = { area = { cards = {} } }

		pile_sync.sync_store_pile_to_area(store, "hand")
		T.assert_equal(#G.dealt_letters.cards, 1)
		T.assert_equal(G.dealt_letters.cards[1], card)
		T.assert_equal(G.dealt_letters.cards[1].pile_id, "hand")
	end)

	T.it("ensure_test_binding syncs piles when table areas exist", function()
		mock_env.reset_game()
		G.dealt_letters = {
			cards = {
				{ letter_card_id = 9, ability = { letter = "Z" }, REMOVED = nil },
			},
		}
		G.draw_pile = { cards = {} }
		G.recycle_stash = { cards = {} }
		G.pattern_row = { area = { cards = {} } }

		require("bridge.store_sync").ensure_test_binding()
		T.assert_equal(#word_game.store():get().piles.hand, 1)
		T.assert_equal(word_game.store():get().piles.hand[1].ability.letter, "Z")
	end)
end)
