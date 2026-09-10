--[[ tests/unit/test_timeline_state.lua - Domain timeline reads from G.GAME mirror ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local Timeline = require("word_game.model.run.timeline")
local Presentation = require("word_game.model.presentation")

T.describe("timeline state mirror", function()
	mock_env.reset_game()

	T.it("reads seconds remaining from G.GAME.timeline_seconds", function()
		G.GAME = { timeline_seconds = 42.5 }
		T.assert_almost_equal(Timeline.seconds_remaining(), 42.5, 0.001)
	end)

	T.it("falls back to jumble time_left when timeline_seconds is unset", function()
		G.GAME = { word_round = { jumble = { time_left = 17 } } }
		T.assert_equal(Timeline.seconds_remaining(), 17)
	end)

	T.it("add_seconds writes G.GAME and emits a one-way apply event", function()
		G.GAME = { timeline_seconds = 30 }
		local applied
		Presentation.on("timeline_apply_seconds", function(seconds)
			applied = seconds
		end)
		Timeline.add_seconds(5)
		T.assert_equal(G.GAME.timeline_seconds, 35)
		T.assert_equal(applied, 5)
		Presentation.clear()
	end)

	T.it("classic goal and target come from G.GAME mirror fields", function()
		G.GAME = {
			timeline_goal_reached = true,
			timeline_progress_target = 150,
		}
		T.assert_true(Timeline.classic_goal_reached())
		T.assert_equal(Timeline.classic_progress_target(), 150)
	end)

	T.it("perk timeline_seconds uses the mirror instead of presentation queries", function()
		local perk_effects = require("word_game.model.perks.effects")
		G.GAME = { timeline_seconds = 12.5 }
		T.assert_almost_equal(perk_effects.timeline_seconds(), 12.5, 0.001)
	end)
end)
