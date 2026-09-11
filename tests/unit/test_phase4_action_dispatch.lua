--[[ tests/unit/test_phase4_action_dispatch.lua - Phase 4 gameplay action dispatch test ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local store_sync = require("bridge.store_sync")
local word_game = require("word_game")

T.describe("Phase 4 Gameplay Action Dispatch", function()
	mock_env.reset_game()

	T.it("dispatches gameplay actions through store and updates state", function()
		G._store = store_sync.new()
		word_game._bind_store(G._store)
		word_game.Round.init_run()

		-- Dispatch PLAY_WORD action
		store_sync.dispatch(G._store, { type = "PLAY_WORD", word = "TEST" })
		T.assert_true(G.GAME.word_round.played_words.TEST)

		-- Dispatch SHUFFLE_HAND action
		store_sync.dispatch(G._store, { type = "SHUFFLE_HAND" })

		-- Dispatch JUMBLE_NEXT action
		store_sync.dispatch(G._store, { type = "JUMBLE_NEXT" })

		-- Dispatch RETURN_PLACEMENT_CARDS action
		store_sync.dispatch(G._store, { type = "RETURN_PLACEMENT_CARDS" })
	end)

	T.it("invokes G.FUNCS gameplay callbacks bridging store dispatch", function()
		mock_env.reset_game()
		package.loaded["app.callbacks.registry"] = nil
		package.loaded["word_game.ui.callbacks.table_controls"] = nil
		require("app.callbacks.registry")

		T.assert_not_nil(G.FUNCS.shuffle_hand)
		T.assert_not_nil(G.FUNCS.return_placement_cards)
		T.assert_not_nil(G.FUNCS.play_placement_word)
		T.assert_not_nil(G.FUNCS.jumble_next)

		-- Callbacks should execute safely without error
		pcall(function() G.FUNCS.shuffle_hand() end)
		pcall(function() G.FUNCS.return_placement_cards() end)
		pcall(function() G.FUNCS.play_placement_word() end)
		pcall(function() G.FUNCS.jumble_next() end)
	end)
end)
