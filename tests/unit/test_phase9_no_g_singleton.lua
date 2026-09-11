--[[ tests/unit/test_phase9_no_g_singleton.lua - PR-9 final: no global G singleton ]]

local T = require("tests.framework")
local BridgeRuntime = require("app.runtime")
local mock_env = require("tests.helpers.mock_env")

T.describe("Phase 9 no G singleton", function()
	T.it("Game() binds bridge/runtime without assigning _G.G", function()
		_G.G = nil
		BridgeRuntime.bind_game(nil)

		require("app.core.util.tables")
		require("app.core.object")
		require("word_game.model.game")
		require("word_game.model.game.globals")

		local game = Game()
		T.assert_nil(_G.G)
		T.assert_not_nil(BridgeRuntime.game())
		T.assert_equal(BridgeRuntime.game(), game)
		T.assert_not_nil(game.SETTINGS)
		T.assert_not_nil(game.STATES)

		mock_env.reset_game()
	end)
end)
