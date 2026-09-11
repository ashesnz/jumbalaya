--[[ tests/unit/test_store_sync.lua - app/bootstrap/store_sync contract ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local store_sync = require("app.bootstrap.store_sync")

T.describe("store_sync", function()
	mock_env.reset_game()

	T.it("replace updates store state", function()
		local store = store_sync.new({ chips = 1 })
		store_sync.replace(store, { chips = 42, word_round = { set = 1 } })
		T.assert_equal(store_sync.get_state(store).chips, 42)
		T.assert_equal(store_sync.get_state(store).word_round.set, 1)
	end)

	T.it("patch shallow-merges store state", function()
		local store = store_sync.new({ chips = 1, word_round = { set = 1, hand_index = 1 } })
		store_sync.patch(store, { chips = 99 })
		T.assert_equal(store_sync.get_state(store).chips, 99)
		T.assert_equal(store_sync.get_state(store).word_round.set, 1)
	end)

	T.it("bind_run adopts a game table snapshot", function()
		local store = store_sync.new()
		store_sync.bind_run(store, { tokens = 7 })
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
