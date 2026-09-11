--[[ tests/unit/test_phase8_model_no_g_game.lua - Phase 8 model/store gates ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local game_access = require("word_game.model.game_access")
local store_sync = require("bridge.store_sync")
local Store = require("jumbalaya_core.store")
local word_game = require("word_game")

T.describe("Phase 8 model and mirror retirement", function()
	mock_env.reset_game()

	T.it("game_access reads and patches via store only", function()
		local store = Store.new({ points = 42, round = 1 })
		word_game._bind_store(store)
		store_sync.bind_run(store, store:get())
		T.assert_equal(game_access.get().points, 42)
		game_access.patch({ round = 3 })
		T.assert_equal(store:get().round, 3)
		T.assert_equal(game_access.get().round, 3)
		mock_env.reset_game()
	end)

	T.it("sync_to_g no longer mirrors onto G.GAME (PR-2)", function()
		G.GAME = { points = 1 }
		store_sync.sync_to_g(word_game.store())
		T.assert_equal(G.GAME.points, 1, "G.GAME should remain unchanged when mirror is retired")
	end)

	T.it("game_access.dispatch updates store without model touching G.GAME", function()
		mock_env.reset_game()
		game_access.dispatch({ type = "SHUFFLE_HAND" })
		T.assert_equal(word_game.store():get().shuffle_hand_count, 1)
	end)

	T.it("word_game/model contains no G.GAME references", function()
		local handle = io.popen("rg -l '\\bG\\.GAME\\b' word_game/model --glob '*.lua' 2>/dev/null || true")
		local output = handle and handle:read("*a") or ""
		if handle then handle:close() end
		T.assert_equal(output:gsub("%s+", ""), "", "model layer must not reference G.GAME")
	end)
end)
