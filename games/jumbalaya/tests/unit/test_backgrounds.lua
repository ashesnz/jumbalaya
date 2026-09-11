--[[ tests/unit/test_backgrounds.lua - Match background staging ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("Match backgrounds", function()
	mock_env.reset_game()
	local backgrounds = require("word_game.ui.layout.backgrounds")

	T.it("uses the garden leaves board for every stage", function()
		for _, stage in ipairs({ {1, 1}, {1, 4}, {2, 3}, {8, 1} }) do
			backgrounds.stage(stage[1], stage[2])
			T.assert_equal(G.ARGS.run_bg.mode, "garden", "stage should select the garden board")
		end
	end)
end)
