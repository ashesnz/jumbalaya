--[[ tests/unit/test_phase5_4_persistence.lua - Phase 5.4 store-based persistence test ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local Store = require("jumbalaya_core.store")
local run_save = require("word_game.model.persistence.run_save")
require("app.core.persistence.save")

T.describe("Phase 5.4 Store-based Persistence", function()
	mock_env.reset_game()

	T.it("queues run snapshot from store state without CardArea:save()", function()
		local store = Store.new({
			points = 150,
			round = 2,
			word_round = { set = 1, hand_index = 2, target = 30 },
			piles = {
				hand = { { id = 1, letter = "A", pile_id = "hand" } },
				draw = { { id = 2, letter = "B", pile_id = "draw" } },
				pattern = {},
				bonus = {},
				discard = {},
			}
		})
		G._store = store
		G.ARGS = {}

		queue_run_snapshot()
		T.assert_not_nil(G.ARGS.run_snapshot)
		T.assert_not_nil(G.ARGS.run_snapshot.store)
		T.assert_equal(G.ARGS.run_snapshot.store.points, 150)
		T.assert_equal(#G.ARGS.run_snapshot.store.piles.hand, 1)
		T.assert_equal(G.ARGS.run_snapshot.store.piles.hand[1].letter, "A")

		G._store = nil
		G.ARGS = nil
	end)

	T.it("restores card areas / piles from store state snapshot", function()
		local store = Store.new()
		G._store = store

		local snapshot = {
			store = {
				points = 250,
				round = 3,
				word_round = { set = 2, hand_index = 1, target = 50 },
				piles = {
					hand = { { id = 10, letter = "X", pile_id = "hand" } },
					draw = { { id = 11, letter = "Y", pile_id = "draw" } },
					pattern = {},
					bonus = {},
					discard = {},
				}
			}
		}

		run_save.restore_card_areas(snapshot)

		local state = store:get()
		T.assert_equal(state.points, 250)
		T.assert_equal(state.round, 3)
		T.assert_equal(#state.piles.hand, 1)
		T.assert_equal(state.piles.hand[1].letter, "X")
		T.assert_equal(#G.letter_inventory, 2)

		G._store = nil
		G.letter_inventory = nil
	end)
end)
