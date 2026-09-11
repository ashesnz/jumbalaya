--[[ tests/unit/test_phase5_pile_sync.lua - Phase 5 pile dual-write bridge test ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local pile_sync = require("bridge.pile_sync")
local Store = require("jumbalaya_core.store")
local pile_selectors = require("jumbalaya_core.store.selectors.piles")

T.describe("Phase 5 Pile Sync Bridge", function()
	mock_env.reset_game()

	T.it("snapshots live CardArea cards into store piles", function()
		local store = Store.new()
		G._store = store

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

		G._store = nil
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
		T.assert_equal(#G._store:get().piles.hand, 1)
		T.assert_equal(G._store:get().piles.hand[1].ability.letter, "Z")
	end)
end)
