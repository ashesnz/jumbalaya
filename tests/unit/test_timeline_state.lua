--[[ tests/unit/test_timeline_state.lua - Domain timeline reads from store snapshot ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local Timeline = require("word_game.model.run.timeline")
local Presentation = require("word_game.model.presentation")
local game_access = require("word_game.model.game_access")

T.describe("timeline state mirror", function()
	mock_env.reset_game()

	T.it("reads seconds remaining from G.GAME.timeline_seconds", function()
		mock_env.publish_game({ run_mode = "time_run", timeline_seconds = 42.5 })
		T.assert_almost_equal(Timeline.seconds_remaining(), 42.5, 0.001)
	end)

	T.it("returns math.huge when timeline_seconds is unset", function()
		mock_env.publish_game({ run_mode = "time_run" })
		T.assert_equal(Timeline.seconds_remaining(), math.huge)
	end)

	T.it("update decrements timeline_seconds on TABLE_BOARD tick", function()
		mock_env.publish_game({
			run_mode = "time_run",
			timeline_duration = 60,
			timeline_seconds = 60,
			timeline_active = true,
			timeline_frozen = false,
		})
		Timeline.update(15)
		T.assert_almost_equal(G.GAME.timeline_seconds, 45, 0.001)
		Timeline.update(40)
		T.assert_almost_equal(G.GAME.timeline_seconds, 5, 0.001)
		Timeline.update(10)
		T.assert_equal(G.GAME.timeline_seconds, 0)
	end)

	T.it("add_seconds writes G.GAME and emits sync event", function()
		mock_env.publish_game({ run_mode = "time_run", timeline_seconds = 30, timeline_duration = 60 })
		local synced
		Presentation.on("timeline_sync_from_model", function()
			synced = true
		end)
		Timeline.add_seconds(5)
		T.assert_equal(G.GAME.timeline_seconds, 35)
		T.assert_true(synced)
		Presentation.clear()
	end)

	T.it("classic goal and target come from G.GAME mirror fields", function()
		mock_env.publish_game({
			timeline_goal_reached = true,
			timeline_progress_target = 150,
		})
		T.assert_true(Timeline.classic_goal_reached())
		T.assert_equal(Timeline.classic_progress_target(), 150)
	end)

	T.it("update_timer reports fuse expiry from timeline_seconds", function()
		mock_env.reset_game()
		game_access.mutate(function(g)
			g.run_mode = "time_run"
			g.word_round = { mode = "jumble", jumble = { total_score = 0 } }
			g.timeline_seconds = 0
			g.timeline_active = true
		end)
		local Jumble = require("word_game.model.jumble")
		T.assert_true(Jumble.update_timer())
		game_access.mutate(function(g)
			g.timeline_seconds = 5
		end)
		T.assert_false(Jumble.update_timer())
	end)

	T.it("perk timeline_seconds uses the mirror instead of presentation queries", function()
		local perk_effects = require("word_game.model.perks.effects")
		mock_env.publish_game({ run_mode = "time_run", timeline_seconds = 12.5 })
		T.assert_almost_equal(perk_effects.timeline_seconds(), 12.5, 0.001)
	end)
end)
