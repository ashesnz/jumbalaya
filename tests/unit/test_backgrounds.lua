--[[ tests/unit/test_backgrounds.lua - Match background staging ]]

local T = require("tests.framework")

T.describe("Match backgrounds", function()
	local backgrounds = require("word_game.ui.layout.backgrounds")

	T.it("uses the garden leaves board for every stage", function()
		T.assert_true(backgrounds.is_garden_stage(1, 1))
		T.assert_true(backgrounds.is_garden_stage(1, 4))
		T.assert_true(backgrounds.is_garden_stage(2, 3))
		T.assert_true(backgrounds.is_garden_stage(8, 1))
	end)
end)
