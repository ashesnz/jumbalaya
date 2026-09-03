--[[ tests/unit/test_run_mode.lua - Preferred Classic / Time Run mode ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local RunMode = require("word_game.model.run_mode")

T.describe("run mode preference", function()
	T.it("defaults to time run when no preference is saved", function()
		mock_env.reset_game()
		G.SETTINGS = G.SETTINGS or {}
		G.SETTINGS.preferred_run_mode = nil
		T.assert_equal(RunMode.preferred(), "time_run")
		T.assert_equal(RunMode.resolve_for_new_run(nil), "time_run")
	end)

	T.it("remembers the last explicitly chosen mode", function()
		mock_env.reset_game()
		G.SETTINGS = G.SETTINGS or {}
		RunMode.set_preferred("classic")
		T.assert_equal(RunMode.preferred(), "classic")
		T.assert_equal(RunMode.resolve_for_new_run(nil), "classic")
		RunMode.set_preferred("time_run")
		T.assert_equal(RunMode.preferred(), "time_run")
	end)

	T.it("uses an explicit mode when the title buttons pass one", function()
		mock_env.reset_game()
		G.SETTINGS = G.SETTINGS or {}
		RunMode.set_preferred("time_run")
		T.assert_equal(RunMode.resolve_for_new_run("classic"), "classic")
	end)

	T.it("falls back to the saved preference for restart and new-run flows", function()
		mock_env.reset_game()
		G.SETTINGS = G.SETTINGS or {}
		RunMode.set_preferred("classic")
		T.assert_equal(RunMode.resolve_for_new_run(), "classic")
	end)

	T.it("ends the hand on target in time run only", function()
		mock_env.reset_game()
		G.GAME = G.GAME or {}
		G.GAME.run_mode = "time_run"
		T.assert_true(RunMode.ends_hand_on_target())
		G.GAME.run_mode = "classic"
		T.assert_false(RunMode.ends_hand_on_target())
	end)
end)
