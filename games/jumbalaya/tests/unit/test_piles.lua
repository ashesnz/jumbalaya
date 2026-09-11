--[[ tests/unit/test_piles.lua - Store pile sync and chrome release ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local piles = require("word_game.model.piles")
local Store = require("jumbalaya_core.store")
local pile_selectors = require("jumbalaya_core.store.selectors.piles")
local word_game = require("word_game")

T.describe("Store piles", function()
	mock_env.reset_game()

	T.it("snapshots live pile hosts into store piles", function()
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

		piles.sync_hosts_to_store(store)
		local state = store:get()
		T.assert_equal(#pile_selectors.hand_cards(state), 2)
		T.assert_equal(#pile_selectors.draw_cards(state), 1)
		T.assert_equal(state.piles.hand[1].id, 1)
		T.assert_equal(state.piles.hand[1].pile_id, "hand")
	end)

	T.it("chrome_release_enabled is on", function()
		T.assert_true(piles.chrome_release_enabled())
	end)

	T.it("release_static_chrome snapshots then clears resting pile host cards", function()
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

		piles.release_static_chrome(store, { "hand" })
		local state = store:get()
		T.assert_equal(#pile_selectors.hand_cards(state), 2)
		T.assert_equal(#G.dealt_letters.cards, 1)
		T.assert_equal(G.dealt_letters.cards[1], dragging)
	end)

	T.it("ensure_test_binding syncs piles when table hosts exist", function()
		mock_env.reset_game()
		G.dealt_letters = {
			cards = {
				{ letter_card_id = 9, ability = { letter = "Z" }, REMOVED = nil },
			},
		}
		G.draw_pile = { cards = {} }
		G.recycle_stash = { cards = {} }
		G.pattern_row = { area = { cards = {} } }

		require("app.bootstrap.store_sync").ensure_test_binding()
		T.assert_equal(#word_game.store():get().piles.hand, 1)
		T.assert_equal(word_game.store():get().piles.hand[1].ability.letter, "Z")
	end)
end)
