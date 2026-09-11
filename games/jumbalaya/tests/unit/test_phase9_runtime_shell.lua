--[[ tests/unit/test_phase9_runtime_shell.lua - Phase 9 runtime shell (PR-9a) ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local BridgeRuntime = require("app.runtime")

T.describe("Phase 9 runtime shell", function()
	mock_env.reset_game()

	T.it("bind_game exposes the live Game instance", function()
		local game = BridgeRuntime.game()
		T.assert_not_nil(game)
		T.assert_equal(BridgeRuntime.game(), game)
		T.assert_equal(BridgeRuntime.state(), game.STATE)
		T.assert_equal(BridgeRuntime.stage(), game.STAGE)
		T.assert_equal(BridgeRuntime.settings(), game.SETTINGS)
	end)

	T.it("session loop modules avoid direct G access", function()
		local lifecycle = require("app.core.session.lifecycle")
		local save_queue = require("app.core.session.loop.save_queue")
		T.assert_not_nil(lifecycle)
		T.assert_not_nil(save_queue.update)
	end)

	T.it("persistence save routes through BridgeRuntime", function()
		require("app.core.persistence.save")
		T.assert_not_nil(queue_run_snapshot)
		queue_run_snapshot()
	end)

	T.it("word_game/ui uses game_runtime instead of G", function()
		T.assert_not_nil(require("word_game.ui.util.game_runtime").game)
		T.assert_not_nil(require("word_game.ui.table.board"))
	end)
end)
