--[[ tests/unit/test_phase3_engine_services.lua - Phase 3 engine service interfaces and adapters test ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local Engine = require("jumbalaya-engine")
local Store = require("jumbalaya_core.store")

T.describe("Phase 3 Engine Service Interfaces", function()
	mock_env.reset_game()

	T.it("initializes Renderer service and calls adapters", function()
		local called = false
		local mock_adapter = {
			draw_card = function(view, rect) called = true end
		}
		local renderer = Engine.Renderer.new(mock_adapter)
		renderer:draw_card({}, {})
		T.assert_true(called)
	end)

	T.it("initializes InputService and dispatches actions to store", function()
		local store = Store.new({ count = 0 })
		local input_svc = Engine.InputService.new(store)
		T.assert_not_nil(input_svc:on_pointer_down(10, 20))
		input_svc:on_action({ type = "TEST_ACTION" })
	end)

	T.it("initializes AudioService", function()
		local audio_svc = Engine.AudioService.new()
		T.assert_not_nil(audio_svc)
		-- smoke call play
		audio_svc:play("click", { gain = 1 })
	end)

	T.it("initializes Clock service and advances time", function()
		local clock = Engine.Clock.new(0)
		T.assert_equal(clock:get_time(), 0)
		clock:advance(0.5)
		T.assert_equal(clock:get_time(), 0.5)
	end)
end)
