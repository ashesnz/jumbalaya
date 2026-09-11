--[[ tests/unit/test_store_sync.lua - bridge/store_sync contract ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local store_sync = require("bridge.store_sync")

T.describe("store_sync shim", function()
	mock_env.reset_game()

	T.it("replace mirrors state onto G.GAME", function()
		local store = store_sync.new({ chips = 1 })
		store_sync.replace(store, { chips = 42, word_round = { set = 1 } })
		T.assert_equal(G.GAME.chips, 42)
		T.assert_equal(G.GAME.word_round.set, 1)
	end)

	T.it("patch shallow-merges and mirrors to G.GAME", function()
		local store = store_sync.new({ chips = 1, word_round = { set = 1, hand_index = 1 } })
		store_sync.sync_to_g(store)
		store_sync.patch(store, { chips = 99 })
		T.assert_equal(G.GAME.chips, 99)
		T.assert_equal(G.GAME.word_round.set, 1)
	end)

	T.it("sync_from_g adopts legacy G.GAME", function()
		G.GAME = { tokens = 7 }
		local store = store_sync.new()
		store_sync.sync_from_g(store)
		T.assert_equal(store_sync.get_state(store).tokens, 7)
	end)

	T.it("notifies subscribers on replace and patch", function()
		local store = store_sync.new({})
		local seen = {}
		store_sync.subscribe(store, function(state)
			seen[#seen + 1] = state.chips
		end)
		store_sync.replace(store, { chips = 1 })
		store_sync.patch(store, { chips = 2 })
		T.assert_equal(#seen, 2)
		T.assert_equal(seen[1], 1)
		T.assert_equal(seen[2], 2)
	end)
end)
