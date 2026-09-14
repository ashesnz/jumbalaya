--[[ tests/unit/test_run_backgrounds.lua - Run garden backdrop (green + falling leaves) ]]

local mock_env = require("tests.helpers.mock_env")
local backgrounds = require("word_game.ui.layout.backgrounds")

local T = require("tests.framework")

T.describe("run backgrounds", function()
	mock_env.reset_game()
	mock_env.ensure_engine_globals()

	local game = require("word_game.ui.util.game_runtime").game()

	T.it("uses the garden leaves board for every stage", function()
		T.assert_true(backgrounds.is_garden_stage(1, 1))
		T.assert_true(backgrounds.is_garden_stage(1, 6))
		T.assert_true(backgrounds.is_garden_stage(2, 3))
		T.assert_true(backgrounds.is_garden_stage(8, 1))
	end)

	T.it("garden installs SPLASH_BACK with garden_leaves shader", function()
		game.ARGS = game.ARGS or {}
		game.SHADERS = game.SHADERS or {}
		game.SHADERS.garden_leaves = game.SHADERS.garden_leaves or {}

		backgrounds.garden()

		T.assert_not_nil(game.SPLASH_BACK)
		T.assert_equal(game.ARGS.run_bg.mode, "garden")
		T.assert_equal(game.SPLASH_BACK.draw_steps[1].shader, "garden_leaves")
	end)

	T.it("presentation run_backgrounds installs the garden backdrop", function()
		mock_env.install_presentation()
		game.SPLASH_BACK = nil
		require("word_game.model.presentation").emit("run_backgrounds")
		T.assert_not_nil(game.SPLASH_BACK)
		T.assert_equal(game.ARGS.run_bg.mode, "garden")
	end)

	if love and love.graphics and love.graphics.newShader then
		T.it("garden_leaves.fs compiles via GameFiles", function()
			local GameFiles = require("app.platform.game_files")
			local shader, err = GameFiles.load_shader("resources/shaders/garden_leaves.fs")
			T.assert_not_nil(shader, tostring(err))
			if shader and shader.release then
				shader:release()
			end
		end)
	end
end)
