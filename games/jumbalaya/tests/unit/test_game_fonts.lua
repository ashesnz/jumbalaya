--[[ tests/unit/test_game_fonts.lua - resources/fonts load via GameFiles ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local GameFonts = require("word_game.ui.util.fonts")

T.describe("game fonts", function()
	mock_env.setup()

	T.it("loads Sniglet for score bubble text", function()
		local font = GameFonts.sniglet(32)
		T.assert_not_nil(font)
		T.assert_true(font.getHeight() > 0)
	end)
end)
