--[[ tests/unit/test_phase4_action_dispatch.lua - Phase 4 gameplay action dispatch test ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local store_sync = require("bridge.store_sync")
local action_dispatch = require("bridge.action_dispatch")
local Funcs = require("bridge.funcs_registry")
local word_game = require("word_game")

T.describe("Phase 4 Gameplay Action Dispatch", function()
	mock_env.reset_game()

	T.it("dispatches gameplay actions through store and updates state", function()
		local store = store_sync.new()
		word_game._bind_store(store)
		require("app.bootstrap.engine_services_boot").install()
		word_game.Round.init_run()

		store_sync.dispatch(store, { type = "PLAY_WORD", word = "TEST" })
		local state = store:get()
		T.assert_true(state.word_round.played_words.TEST)

		store_sync.dispatch(store, { type = "SHUFFLE_HAND" })
		T.assert_equal(store:get().shuffle_hand_count, 1)

		store_sync.dispatch(store, { type = "JUMBLE_NEXT" })
		T.assert_equal(store:get().last_gameplay_action, "JUMBLE_NEXT")

		store_sync.dispatch(store, { type = "RETURN_PLACEMENT_CARDS" })
		T.assert_equal(store:get().last_gameplay_action, "RETURN_PLACEMENT_CARDS")
	end)

	T.it("routes gameplay callbacks through InputService", function()
		mock_env.reset_game()
		local store = store_sync.new()
		word_game._bind_store(store)
		require("app.bootstrap.engine_services_boot").install()
		package.loaded["app.callbacks.registry"] = nil
		package.loaded["word_game.ui.callbacks.table_controls"] = nil
		require("app.callbacks.registry")

		T.assert_not_nil(Funcs.get("shuffle_hand"))
		T.assert_not_nil(Funcs.get("return_placement_cards"))
		T.assert_not_nil(Funcs.get("play_placement_word"))
		T.assert_not_nil(Funcs.get("jumble_next"))

		local before = store:get().shuffle_hand_count or 0
		pcall(function() Funcs.dispatch("shuffle_hand") end)
		T.assert_equal(store:get().shuffle_hand_count, before + 1)
	end)

	T.it("dispatches placement word payload via gameplay controller", function()
		mock_env.reset_game()
		mock_env.publish_game({
			placement_word = "CAT",
			placement_word_valid = true,
			word_round = { played_words = {} },
		})

		action_dispatch.dispatch_func("play_placement_word", { word = "CAT" })
		T.assert_true(word_game.store():get().word_round.played_words.CAT)
	end)

	T.it("emits app actions for menu lifecycle callbacks", function()
		mock_env.reset_game()
		local app_events = require("app.services.app_events")
		local seen = {}
		app_events.on("APP_RETURN_TO_MENU", function(action)
			seen[#seen + 1] = action.type
		end)
		action_dispatch.dispatch({ type = "APP_RETURN_TO_MENU" })
		T.assert_equal(seen[1], "APP_RETURN_TO_MENU")
	end)

	T.it("attaches action dispatch helpers to InputRouter", function()
		mock_env.reset_game()
		local router = require("app.core.input.router")
		T.assert_not_nil(router.dispatch_action)
		T.assert_not_nil(router.dispatch_func)
	end)
end)
