--[[ tests/unit/test_phase3_engine_services.lua - Phase 3 engine service interfaces and adapters test ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local Engine = require("jumbalaya-engine")
local Store = require("jumbalaya_core.store")

T.describe("Phase 3 Engine Service Interfaces", function()
	mock_env.reset_game()

	T.it("initializes Renderer service and calls Love2D adapters", function()
		local called = false
		local mock_adapter = {
			draw_card = function(view, rect) called = true end
		}
		local renderer = Engine.Renderer.new(mock_adapter)
		renderer:draw_card({}, {})
		T.assert_true(called)

		local love_renderer = Engine.Renderer.love2d()
		T.assert_not_nil(love_renderer)
	end)

	T.it("initializes InputService and dispatches mapped gameplay actions", function()
		local store = Store.new({ word_round = { played_words = {} } })
		local input_svc = Engine.InputService.new(store)
		T.assert_not_nil(input_svc:on_pointer_down(10, 20))
		T.assert_not_nil(input_svc:action_for_func("shuffle_hand"))
		input_svc:dispatch_func("shuffle_hand")
		input_svc:on_action({ type = "TEST_ACTION" })
	end)

	T.it("initializes AudioService and reacts to store actions", function()
		local played = {}
		local orig_play_sfx = _G.play_sfx
		_G.play_sfx = function(id) played[#played + 1] = id end
		local store = Store.new({ word_round = { played_words = {} } })
		local audio_svc = Engine.AudioService.new()
		audio_svc:bind_store(store)
		store:dispatch({ type = "PLAY_WORD", word = "cat" })
		T.assert_equal(played[1], "card1")
		_G.play_sfx = orig_play_sfx
	end)

	T.it("initializes Clock service with injected and global time", function()
		local clock = Engine.Clock.new(0)
		T.assert_equal(clock:get_time(), 0)
		clock:advance(0.5)
		T.assert_equal(clock:get_time(), 0.5)

		G.TIMERS = G.TIMERS or {}
		G.TIMERS.REAL = 12.5
		local global_clock = Engine.Clock.from_globals()
		T.assert_equal(global_clock:get_time(), 12.5)
	end)

	T.it("builds EngineContext and binds at boot", function()
		mock_env.reset_game()
		local word_game = require("word_game")
		local store = word_game.store()
		local engine = word_game.engine()
		T.assert_not_nil(store)
		T.assert_not_nil(engine)
		T.assert_not_nil(engine.renderer)
		T.assert_not_nil(engine.input)
		T.assert_not_nil(engine.audio)
		T.assert_not_nil(engine.clock)
		T.assert_equal(engine.store, store)
		T.assert_nil(G._store)
		T.assert_nil(G._engine)
	end)
end)
