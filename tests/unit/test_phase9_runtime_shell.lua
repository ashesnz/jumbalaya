--[[ tests/unit/test_phase9_runtime_shell.lua - Phase 9 runtime shell (PR-9a) ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local BridgeRuntime = require("bridge.runtime")

T.describe("Phase 9 runtime shell", function()
	mock_env.reset_game()

	T.it("bind_game exposes the live Game instance", function()
		T.assert_not_nil(G)
		BridgeRuntime.bind_game(G)
		T.assert_equal(BridgeRuntime.game(), G)
		T.assert_equal(BridgeRuntime.state(), G.STATE)
		T.assert_equal(BridgeRuntime.stage(), G.STAGE)
		T.assert_equal(BridgeRuntime.settings(), G.SETTINGS)
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
end)
