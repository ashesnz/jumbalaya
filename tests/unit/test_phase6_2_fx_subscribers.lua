--[[ tests/unit/test_phase6_2_fx_subscribers.lua - Phase 6.2 FX modules as store & presentation subscribers test ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local Store = require("jumbalaya_core.store")
local Engine = require("jumbalaya-engine")
local Presentation = require("word_game.model.presentation")
local fx_subscribers = require("word_game.ui.fx_subscribers")

T.describe("Phase 6.2 FX Modules as Subscribers", function()
	mock_env.reset_game()
	fx_subscribers.reset()

	T.it("forwards PLAY_RESOLVED from Presentation to engine EventBus", function()
		local engine = Engine.Context.new({ store = Store.new() })
		Presentation.bind_events(engine.events)

		local event_handled = false
		engine.events:on("PLAY_RESOLVED", function(result)
			event_handled = true
			T.assert_equal(result.kind, "word_play")
		end)

		Presentation.emit("PLAY_RESOLVED", { kind = "word_play" })
		T.assert_true(event_handled)
		Presentation.clear()
	end)

	T.it("fx_subscribers refresh jumble HUD on store score changes", function()
		G.STAGE = G.STAGES.RUN
		local store = Store.new({
			word_round = {
				jumble = { total_score = 10 },
			},
		})
		local engine = Engine.Context.new({ store = store })
		local hud_refreshed = false
		Presentation.on("jumble_hud_refresh", function()
			hud_refreshed = true
		end)

		fx_subscribers.install(engine, {})
		store:dispatch({ type = "GAME_PATCH", patch = {
			word_round = { jumble = { total_score = 25 } },
		} })
		T.assert_true(hud_refreshed)
		Presentation.clear()
	end)

	T.it("sidebar and trade views track store revisions", function()
		local views_install = require("word_game.ui.views.install")
		views_install.reset()
		local store = Store.new({ run_state = { tokens = 5 } })
		local engine = Engine.Context.new({ store = store })
		views_install.install_sidebar(engine)
		views_install.install_trade(engine)
		local sidebar = views_install.sidebar_view()
		local trade = views_install.trade_view()
		store:dispatch({ type = "GAME_PATCH", patch = { run_state = { tokens = 8 } } })
		T.assert_true(sidebar:revision() > 0)
		store:dispatch({ type = "TRADE_PICK" })
		T.assert_true(trade:revision() > 0)
	end)

	T.it("subscribes presentation hooks for score banner and word feedback", function()
		local banner_reset = false
		Presentation.on("score_banner_reset", function(target)
			banner_reset = true
			T.assert_equal(target, 100)
		end)

		Presentation.emit("score_banner_reset", 100)
		T.assert_true(banner_reset)
		Presentation.clear()
	end)
end)
