--[[ tests/unit/test_phase2_store_boot.lua - Phase 2 store boot and round dual-write integration ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local store_sync = require("bridge.store_sync")
local word_game = require("word_game")

T.describe("Phase 2 Store Integration", function()
	mock_env.reset_game()

	T.it("wires store in mock_env and binds WORD_GAME", function()
		T.assert_not_nil(word_game.store())
		T.assert_nil(G._store)
		T.assert_equal(word_game.state(), G.GAME)
	end)

	T.it("dual-writes round init and start_hand via dispatch", function()
		word_game.Round.init_run()

		T.assert_not_nil(G.GAME.word_round)
		T.assert_not_nil(word_game.store():get().word_round)
		T.assert_equal(G.GAME.word_round.set, word_game.store():get().word_round.set)
		T.assert_equal(G.GAME.word_round.hand_index, word_game.store():get().word_round.hand_index)

		word_game.Round.start_hand(1, 2)
		T.assert_equal(G.GAME.word_round.hand_index, 2)
		T.assert_equal(word_game.store():get().word_round.hand_index, 2)
	end)

	T.it("bind_run adopts a fresh game table at run start", function()
		local store = store_sync.new()
		local game_table = { points = 5, word_round = { set = 2, hand_index = 3, played_words = {} } }
		store_sync.bind_run(store, game_table)
		T.assert_equal(G.GAME, game_table)
		T.assert_equal(store:get(), game_table)
	end)

	T.it("dispatch mirrors token changes onto G.GAME", function()
		mock_env.reset_game()
		require("word_game.model.run.state").get()
		word_game.Run.State.add_tokens(10)
		T.assert_equal(G.GAME.run_state.tokens, 10)
		T.assert_equal(word_game.store():get().run_state.tokens, 10)
	end)

	T.it("marks trade used via store dispatch", function()
		mock_env.reset_game()
		require("word_game.model.run.state").get()
		local trade = require("word_game.model.trade")
		T.assert_true(trade.can_use())
		trade.mark_used()
		T.assert_false(trade.can_use())
		T.assert_true(word_game.store():get().run_state.trade_used_this_hand)
	end)

	T.it("dual-writes placement preview and busy flags via game_access", function()
		mock_env.reset_game()
		local placement_word = require("word_game.model.jumble.placement_word")
		local busy = require("word_game.model.run.busy")

		placement_word.clear()
		T.assert_equal(G.GAME.placement_word, "")
		T.assert_equal(word_game.store():get().placement_word, "")

		busy.set("trade_ui_busy", true)
		T.assert_true(G.GAME.trade_ui_busy)
		T.assert_true(word_game.store():get().trade_ui_busy)

		busy.clear()
		T.assert_nil(G.GAME.trade_ui_busy)
		T.assert_nil(word_game.store():get().trade_ui_busy)
	end)

	T.it("dual-writes timeline fuse state via game_access mutate", function()
		mock_env.reset_game()
		local timeline = require("word_game.model.run.timeline")
		timeline.reset(45)
		T.assert_equal(G.GAME.timeline_seconds, 45)
		T.assert_equal(word_game.store():get().timeline_seconds, 45)
	end)
end)
