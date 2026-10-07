--[[ tests/unit/test_game_fonts.lua - resources/fonts load via GameFiles ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local GameFiles = require("app.platform.game_files")
local GameFonts = require("word_game.ui.util.fonts")

T.describe("game fonts", function()
	mock_env.setup()

	T.it("loads Outfit-Bold from resources/fonts", function()
		GameFiles.ensure_mounted()
		T.assert_true(GameFiles.exists(GameFonts.OUTFIT_BOLD))
		local font = GameFonts.outfit(24)
		T.assert_not_nil(font)
		T.assert_true(font.getHeight() > 0)
	end)

	T.it("loads Sniglet for score bubble text", function()
		local font = GameFonts.sniglet(32)
		T.assert_not_nil(font)
		T.assert_true(font.getHeight() > 0)
	end)
end)
