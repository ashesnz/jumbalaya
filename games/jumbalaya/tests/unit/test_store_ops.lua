--[[ tests/unit/test_store_ops.lua - word_game.model.store_ops contract ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local store_ops = require("word_game.model.store_ops")

T.describe("store_ops", function()
	mock_env.reset_game()

	T.it("replace updates store state", function()
		local store = store_ops.new({ chips = 1 })
		store_ops.replace(store, { chips = 42, word_round = { set = 1 } })
		T.assert_equal(store_ops.get_state(store).chips, 42)
		T.assert_equal(store_ops.get_state(store).word_round.set, 1)
	end)

	T.it("patch shallow-merges store state", function()
		local store = store_ops.new({ chips = 1, word_round = { set = 1, hand_index = 1 } })
		store_ops.patch(store, { chips = 99 })
		T.assert_equal(store_ops.get_state(store).chips, 99)
		T.assert_equal(store_ops.get_state(store).word_round.set, 1)
	end)

	T.it("bind_run adopts a game table snapshot", function()
		local store = store_ops.new()
		store_ops.bind_run(store, { tokens = 7 })
		T.assert_equal(store_ops.get_state(store).tokens, 7)
	end)

	T.it("notifies subscribers on replace and patch", function()
		local store = store_ops.new({})
		local seen = {}
		store_ops.subscribe(store, function(state)
			seen[#seen + 1] = state.chips
		end)
		store_ops.replace(store, { chips = 1 })
		store_ops.patch(store, { chips = 2 })
		T.assert_equal(#seen, 2)
		T.assert_equal(seen[1], 1)
		T.assert_equal(seen[2], 2)
	end)

	T.it("syncs shell.game().GAME alias after dispatch", function()
		mock_env.reset_game()
		mock_env.patch_game({ round = 9 })
		T.assert_equal(mock_env.game_state().round, 9)
		T.assert_equal(G.GAME.round, 9)
	end)
end)
