--[[ tests/unit/test_title_screen.lua
     Tests for the Jumbalaya title screen, Play / Options / Quit buttons,
     Stage 1-1 transition, and title screen bypass configuration.
]]

local T = require("tests.framework")
local MockEnv = require("tests.helpers.mock_env")

	T.describe("Title Screen & Jumbalaya Menu", function()
	T.it("generates main menu UI tree containing only Play, Options, and Quit buttons", function()
		MockEnv.setup()
		require("app.core.util.tables")
		require("app.core.util.geometry")
		require("word_game.ui.localize")
		require("word_game.ui.widgets")
		require("word_game.ui.menu")

		local ui_tree = build_main_menu_buttons()
		T.assert_not_nil(ui_tree, "Main menu UI tree should be created")

		local buttons_found = {}
		local function scan_nodes(node)
			if type(node) ~= "table" then return end
			if node.config and node.config.button then
				buttons_found[node.config.button] = true
			end
			if node.nodes then
				for _, child in ipairs(node.nodes) do
					scan_nodes(child)
				end
			end
		end

		scan_nodes(ui_tree)

		T.assert_true(buttons_found["begin_run"], "Play button with start_run callback must be present")
		T.assert_true(buttons_found["open_options"], "Options button must be present")
		T.assert_true(buttons_found["quit"], "Quit button must be present")
		T.assert_nil(buttons_found["card_gallery"], "Collection button should not be present on main menu")
		T.assert_nil(buttons_found["go_to_discord"], "Discord button should not be present on main menu")
		T.assert_nil(buttons_found["go_to_twitter"], "Twitter button should not be present on main menu")
	end)

	T.it("registers Jumbalaya atlas with correct paths and dimensions", function()
		MockEnv.setup()
		require("app.core.util.tables")
		require("app.core.util.geometry")
		require("word_game.model.game")
		require("word_game.model.globals")
		require("app.startup")

		local game = Game()
		game:define_constants()
		T.assert_not_nil(game.UIDEF, "Global UI definition namespace must be initialized before menu loading")
		game:set_render_settings()

		local found_jumbalaya = false
		for _, spec in ipairs(game.asset_atli) do
			if spec.name == "Jumbalaya" then
				found_jumbalaya = true
				T.assert_true(string.find(spec.filename, "Jumbalaya.png") ~= nil, "Jumbalaya filename should be Jumbalaya.png")
			end
		end
		T.assert_true(found_jumbalaya, "Jumbalaya atlas spec must be registered in asset_atli")
	end)

	T.it("supports turning off the title screen with configuration option", function()
		MockEnv.setup()
		require("app.bootstrap")
		require("word_game.model.cards.card")
		require("word_game.ui.cardarea")
		require("app.core.util.tables")
		require("app.core.util.geometry")
		require("word_game.model.game")
		require("word_game.model.globals")
		require("app.startup")

		-- Test with skip_title_screen = true
		local game = Game()
		game:define_constants()
		game.init_background_shaders = function() end
		game.load_card_definitions = function() end
		game.load_profile = function() end
		game.set_language = function() end
		game.set_render_settings = function() end
		game.init_window = function() end
		game.SETTINGS.skip_title_screen = true

		local run_started = false
		game.start_run = function(self, args)
			run_started = true
		end
		game.start_gameplay_board = function(self) end
		game.open_main_menu = function(self)
			T.fail("open_main_menu should not be called when skip_title_screen is true")
		end

		game:launch()
		T.assert_true(run_started, "start_run should be invoked immediately when skip_title_screen = true")

		-- Test with F_SKIP_TITLE_SCREEN = true
		local game2 = Game()
		game2:define_constants()
		game2.init_background_shaders = function() end
		game2.load_card_definitions = function() end
		game2.load_profile = function() end
		game2.set_language = function() end
		game2.set_render_settings = function() end
		game2.init_window = function() end
		game2.F_SKIP_TITLE_SCREEN = true

		local run2_started = false
		game2.start_run = function(self, args)
			run2_started = true
		end
		game2.start_gameplay_board = function(self) end
		game2.open_main_menu = function(self)
			T.fail("open_main_menu should not be called when F_SKIP_TITLE_SCREEN is true")
		end

		game2:launch()
		T.assert_true(run2_started, "start_run should be invoked immediately when F_SKIP_TITLE_SCREEN is true")

		-- Test with title_screen = true (default behavior opens main menu)
		local game3 = Game()
		game3:define_constants()
		game3.init_background_shaders = function() end
		game3.load_card_definitions = function() end
		game3.load_profile = function() end
		game3.set_language = function() end
		game3.set_render_settings = function() end
		game3.init_window = function() end
		game3.F_SKIP_TITLE_SCREEN = false
		game3.SETTINGS.skip_title_screen = false
		game3.SETTINGS.title_screen = true

		local menu_opened = false
		game3.start_run = function(self, args)
			T.fail("start_run should not be called on initial boot when title screen is enabled")
		end
		game3.open_main_menu = function(self)
			menu_opened = true
		end

		game3:launch()
		T.assert_true(menu_opened, "open_main_menu should be opened on initial boot by default")
	end)

	T.it("Play button transitions cleanly into Stage 1-1 gameplay board", function()
		MockEnv.setup()
		require("app.bootstrap")
		require("word_game.model.cards.card")
		require("word_game.ui.cardarea")
		require("app.core.util.tables")
		require("app.core.util.geometry")
		require("word_game.model.game")
		require("word_game.model.globals")
		require("app.startup")
		require("word_game.model.round")

		_G.G = Game()
		_G.G:define_constants()
		_G.G.TIMELINE = Scheduler()
		_G.G.INPUT = InputController()
		_G.G:load_card_definitions()
		package.loaded["app.callbacks.settings"] = nil
		require("app.callbacks.settings")

		T.assert_not_nil(G.FUNCS.begin_run, "G.FUNCS.begin_run must be defined")

		local start_board_called = false
		local real_start_board = G.start_gameplay_board
		G.start_gameplay_board = function(self)
			start_board_called = true
			if real_start_board then real_start_board(self) end
		end

		G.FUNCS.begin_run()

		-- Process queued transition event
		for i = 1, 60 do
			G.TIMERS.REAL = G.TIMERS.REAL + 0.016
			G.TIMERS.TOTAL = G.TIMERS.TOTAL + 0.016
			G.TIMELINE:advance(0.016)
		end

		T.assert_true(start_board_called, "start_gameplay_board should be called from start_run")
		T.assert_not_nil(G.GAME.word_round, "G.GAME.word_round must be initialized")
		T.assert_equal(1, G.GAME.word_round.set, "Stage set should be 1")
		T.assert_equal(1, G.GAME.word_round.hand_index, "Stage hand_index should be 1 (Stage 1-1)")
	end)

	T.it("Options button opens existing options modal", function()
		MockEnv.setup()
		require("app.bootstrap")
		require("word_game.ui.widgets")
		require("word_game.ui.overlays")

		package.loaded["app.callbacks.settings"] = nil
		require("app.callbacks.settings")

		local overlay_opened = false
		G.FUNCS.show_overlay = function(args)
			overlay_opened = true
			T.assert_not_nil(args.definition, "Options modal must have a definition")
		end

		G.FUNCS.open_options()
		T.assert_true(overlay_opened, "G.FUNCS.open_options should open the options overlay menu")
	end)

	T.it("TitleLogo juggles start and end A's, replacing each other and returning", function()
		MockEnv.setup()
		require("app.core.util.tables")
		require("app.core.util.geometry")
		require("word_game.model.game")
		require("word_game.model.globals")
		require("app.core.scene.animated.init")
		require("word_game.ui.title_logo")

		local timings = TitleLogo.CYCLE_TIMINGS
		T.assert_not_nil(timings, "Cycle timings must be defined on TitleLogo")

		local anchors = TitleLogo.LETTER_ANCHORS
		local start_cx = anchors.start.x + anchors.start.ox
		local start_cy = anchors.start.y + anchors.start.oy
		local end_cx = anchors["end"].x + anchors["end"].ox
		local end_cy = anchors["end"].y + anchors["end"].oy

		-- Phase 1: Home rest (e.g. t = 0.2s)
		local s_cx, s_cy, s_rot = TitleLogo.juggle_pose("start", 0.2)
		local e_cx, e_cy, e_rot = TitleLogo.juggle_pose("end", 0.2)
		T.assert_equal(start_cx, s_cx, "Start A should be at home X during home rest")
		T.assert_equal(start_cy, s_cy, "Start A should be at home Y during home rest")
		T.assert_equal(0, s_rot, "Start A rotation should be 0 during home rest")
		T.assert_equal(end_cx, e_cx, "End A should be at home X during home rest")
		T.assert_equal(end_cy, e_cy, "End A should be at home Y during home rest")
		T.assert_equal(0, e_rot, "End A rotation should be 0 during home rest")

		-- Phase 2: Mid-air swap (e.g. at u = 0.5 into swap)
		local t_mid_swap = timings.home_rest + timings.swap * 0.5
		local ms_cx, ms_cy, ms_rot = TitleLogo.juggle_pose("start", t_mid_swap)
		local me_cx, me_cy, me_rot = TitleLogo.juggle_pose("end", t_mid_swap)
		T.assert_true(math.abs(ms_cx - (start_cx + end_cx) * 0.5) < 0.001, "Start A should be midway X during swap")
		T.assert_true(math.abs(me_cx - (start_cx + end_cx) * 0.5) < 0.001, "End A should be midway X during swap")
		T.assert_true(ms_cy < start_cy, "Start A should be elevated in the air during swap")
		T.assert_true(me_cy < end_cy, "End A should be elevated in the air during swap")
		T.assert_true(math.abs(ms_rot) > 0.1, "Start A should be rotating during swap")
		T.assert_true(math.abs(me_rot) > 0.1, "End A should be rotating during swap")

		-- Phase 3: Swapped rest (e.g. t in swapped_rest window)
		local t_swapped = timings.home_rest + timings.swap + timings.swapped_rest * 0.5
		local ss_cx, ss_cy, ss_rot = TitleLogo.juggle_pose("start", t_swapped)
		local se_cx, se_cy, se_rot = TitleLogo.juggle_pose("end", t_swapped)
		T.assert_equal(end_cx, ss_cx, "Start A should be at End slot X during swapped rest (replaced each other)")
		T.assert_equal(end_cy, ss_cy, "Start A should be at End slot Y during swapped rest")
		T.assert_equal(0, ss_rot, "Start A rotation should be 0 during swapped rest")
		T.assert_equal(start_cx, se_cx, "End A should be at Start slot X during swapped rest (replaced each other)")
		T.assert_equal(start_cy, se_cy, "End A should be at Start slot Y during swapped rest")
		T.assert_equal(0, se_rot, "End A rotation should be 0 during swapped rest")

		-- Phase 4: Mid-air return (e.g. at u = 0.5 into return)
		local t_mid_return = timings.home_rest + timings.swap + timings.swapped_rest + timings.return_swap * 0.5
		local mr_s_cx, mr_s_cy, mr_s_rot = TitleLogo.juggle_pose("start", t_mid_return)
		local mr_e_cx, mr_e_cy, mr_e_rot = TitleLogo.juggle_pose("end", t_mid_return)
		T.assert_true(math.abs(mr_s_cx - (start_cx + end_cx) * 0.5) < 0.001, "Start A should be midway X during return")
		T.assert_true(mr_s_cy < end_cy, "Start A should be elevated during return")
		T.assert_true(mr_e_cy < start_cy, "End A should be elevated during return")

		-- Cycle wraps around cleanly back to home position
		local full_cycle = timings.home_rest + timings.swap + timings.swapped_rest + timings.return_swap
		local end_s_cx, end_s_cy, end_s_rot = TitleLogo.juggle_pose("start", full_cycle + 0.1)
		T.assert_equal(start_cx, end_s_cx, "Start A should return to home X when cycle restarts")
		T.assert_equal(start_cy, end_s_cy, "Start A should return to home Y when cycle restarts")
		T.assert_equal(0, end_s_rot, "Start A rotation should reset to 0 when cycle restarts")
	end)
end)
