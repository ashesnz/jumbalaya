--[[ tests/unit/test_game_files.lua - Game asset path helpers ]]

local T = require("tests.framework")
local GameFiles = require("app.platform.game_files")

T.describe("game files", function()
	T.it("reads localization from the game tree", function()
		GameFiles.ensure_mounted()
		T.assert_true(GameFiles.exists("localization/en-us.lua"))
		local source = GameFiles.read("localization/en-us.lua")
		T.assert_not_nil(source)
		T.assert_true(source:find("ui_classic") ~= nil)
	end)
end)
