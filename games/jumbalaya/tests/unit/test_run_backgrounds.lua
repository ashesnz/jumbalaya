--[[ tests/unit/test_run_backgrounds.lua - Run garden backdrop (green + falling leaves) ]]

local mock_env = require("tests.helpers.mock_env")
local backgrounds = require("word_game.ui.layout.backgrounds")

local T = require("tests.framework")

T.describe("run backgrounds", function()
	mock_env.reset_game()
	mock_env.ensure_engine_globals()

	local game = require("word_game.ui.util.game_runtime").game()

	T.it("garden installs SPLASH_BACK with garden_leaves shader", function()
		game.ARGS = game.ARGS or {}
		game.SHADERS = game.SHADERS or {}
		game.SHADERS.garden_leaves = game.SHADERS.garden_leaves or {}

		backgrounds.garden()

		T.assert_not_nil(game.SPLASH_BACK)
		T.assert_true(game.SPLASH_BACK.states.visible)
		T.assert_equal(game.ARGS.run_bg.mode, "garden")
		T.assert_not_nil(game.SPLASH_BACK.draw_steps)
		T.assert_equal(game.SPLASH_BACK.draw_steps[1].shader, "garden_leaves")
	end)

	T.it("run applies the garden backdrop", function()
		game.SPLASH_BACK = nil
		backgrounds.run()
		T.assert_not_nil(game.SPLASH_BACK)
		T.assert_equal(game.ARGS.run_bg.mode, "garden")
	end)

	T.it("presentation run_backgrounds installs the garden backdrop", function()
		mock_env.install_presentation()
		game.SPLASH_BACK = nil
		require("word_game.model.presentation").emit("run_backgrounds")
		T.assert_not_nil(game.SPLASH_BACK)
		T.assert_equal(game.ARGS.run_bg.mode, "garden")
	end)

	T.it("garden does not fall back to swirl when garden_leaves is absent", function()
		game.SHADERS = {}
		game.SPLASH_BACK = nil
		backgrounds.garden()
		T.assert_equal(game.ARGS.run_bg.mode, "garden")
		T.assert_equal(game.SPLASH_BACK.draw_steps[1].shader, "garden_leaves")
	end)
end)
