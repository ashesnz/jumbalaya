--[[ tests/unit/test_phase6_2_fx_subscribers.lua - Phase 6.2 FX modules as store & presentation subscribers test ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local Store = require("jumbalaya_core.store")
local Presentation = require("word_game.model.presentation")

T.describe("Phase 6.2 FX Modules as Subscribers", function()
	mock_env.reset_game()

	T.it("subscribes FX presentation handlers to presentation events", function()
		local event_handled = false
		Presentation.on("PLAY_RESOLVED", function(result)
			event_handled = true
			T.assert_equal(result.kind, "word_play")
		end)

		Presentation.emit("PLAY_RESOLVED", { kind = "word_play" })
		T.assert_true(event_handled)
		Presentation.clear()
	end)

	T.it("subscribes FX modules to store state updates", function()
		local store = Store.new({ points = 100 })
		local notified_score = 0
		store:subscribe(function(state)
			notified_score = state.points
		end)

		store:dispatch({ type = "GAME_PATCH", patch = { points = 150 } })
		T.assert_equal(notified_score, 150)
	end)

	T.it("subscribes presentation hooks for score banner and word feedback", function()
		local banner_reset = false
		Presentation.on("score_banner_reset", function(target)
			banner_reset = true
			T.assert_equal(target, 100)
		end)

		Presentation.emit("score_banner_reset", 100)
		T.assert_true(banner_reset)
		Presentation.clear()
	end)
end)
