--[[ tests/unit/test_title_screen.lua
     Tests for the Jumbalaya title screen, mode buttons, utility bar,
     Stage 1-1 transition, and title screen bypass configuration.
]]

local T = require("tests.framework")
local MockEnv = require("tests.helpers.mock_env")

	T.describe("Title Screen & Jumbalaya Menu", function()
	T.it("generates main menu UI tree with Classic, Time Run, Settings, Stats, and Quit", function()
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

		T.assert_true(buttons_found["begin_classic_run"], "Classic button must be present")
		T.assert_true(buttons_found["begin_time_run"], "Time Run button must be present")
		T.assert_true(buttons_found["open_settings"], "Settings button must be present")
		T.assert_true(buttons_found["show_high_scores"], "Stats button must be present")
		T.assert_true(buttons_found["quit"], "Quit button must be present")
		T.assert_nil(buttons_found["begin_run"], "Legacy Play button should not be on the title screen")
		T.assert_nil(buttons_found["open_options"], "Options overlay should not be on the title screen")
		T.assert_nil(buttons_found["show_credits"], "Credits button should be removed")
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
		T.assert_true(run2_started, "start_run should be invoked immediately when F_SKIP_TITLE_SCREEN = true")

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

	T.it("Classic button transitions cleanly into Stage 1-1 gameplay board", function()
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

		T.assert_not_nil(G.FUNCS.begin_classic_run, "G.FUNCS.begin_classic_run must be defined")

		local start_board_called = false
		local run_mode = nil
		local real_start_board = G.start_gameplay_board
		G.start_gameplay_board = function(self)
			start_board_called = true
			if real_start_board then real_start_board(self) end
		end
		local real_start_run = G.start_run
		G.start_run = function(self, args)
			run_mode = args and args.run_mode
			return real_start_run(self, args)
		end

		G.FUNCS.begin_classic_run()

		-- Process queued transition event
		for i = 1, 60 do
			G.TIMERS.REAL = G.TIMERS.REAL + 0.016
			G.TIMERS.TOTAL = G.TIMERS.TOTAL + 0.016
			G.TIMELINE:advance(0.016)
		end

		T.assert_equal(run_mode, "classic", "Classic should start a classic run")
		T.assert_true(start_board_called, "start_gameplay_board should be called from start_run")
		T.assert_not_nil(G.GAME.word_round, "G.GAME.word_round must be initialized")
		T.assert_equal(1, G.GAME.word_round.set, "Stage set should be 1")
		T.assert_equal(1, G.GAME.word_round.hand_index, "Stage hand_index should be 1 (Stage 1-1)")
	end)

	T.it("registers direct settings and mode run callbacks", function()
		MockEnv.setup()
		require("app.bootstrap")
		T.assert_not_nil(G.FUNCS.open_settings, "Settings should open directly from the title bar")
		T.assert_not_nil(G.FUNCS.begin_classic_run, "Classic mode callback must exist")
		T.assert_not_nil(G.FUNCS.begin_time_run, "Time Run mode callback must exist")
		T.assert_nil(G.FUNCS.show_credits, "Credits overlay callback should be removed")
	end)

	T.it("keeps mode buttons above utility bar with separation", function()
		MockEnv.reset_game()
		require("app.core.util.tables")
		require("app.core.util.geometry")
		require("word_game.ui.localize")
		require("word_game.ui.widgets")
		require("word_game.ui.menu")

		G.C.L_BLACK = G.C.L_BLACK or { 0.1, 0.1, 0.1, 1 }
		G.C.BLUE = G.C.BLUE or { 0.2, 0.4, 0.8, 1 }
		G.C.GREEN = G.C.GREEN or { 0.2, 0.7, 0.3, 1 }
		G.C.ORANGE = G.C.ORANGE or { 0.9, 0.5, 0.1, 1 }
		G.C.FILTER = G.C.FILTER or { 0.5, 0.5, 0.5, 1 }
		G.C.RED = G.C.RED or { 0.8, 0.2, 0.2, 1 }
		G.C.UI = G.C.UI or {}
		G.C.UI.TEXT_LIGHT = G.C.UI.TEXT_LIGHT or { 1, 1, 1, 1 }
		G.C.UI.BUTTON_HOVER = G.C.UI.BUTTON_HOVER or { 0.35, 0.35, 0.35, 1 }

		local real_font = alpha_button_font
		alpha_button_font = function()
			return {
				FONT = {
					getWidth = function(_, str) return #(str or "") * 10 end,
					getHeight = function() return 20 end,
				},
				TEXT_HEIGHT_SCALE = 0.7,
				TEXT_OFFSET = { x = 0, y = 0 },
				FONTSCALE = 0.12,
				squish = 1,
			}
		end

		local ui = LayoutView({
			definition = build_main_menu_buttons(),
			config = { align = "cm", major = G.ROOM_ATTACH },
		})
		local stack_gap = main_menu_stack_gap_tiles(ui)
		alpha_button_font = real_font
		ui:remove()

		local ts = (G.TILESIZE or 20) * (G.TILESCALE or 1)
		local min_gap = 20 / ts
		T.assert_not_nil(stack_gap, "Mode and utility stacks must be measurable")
		T.assert_true(stack_gap >= min_gap * 0.85,
			string.format("Utility row must sit below mode buttons (gap %.3f, need %.3f)",
				stack_gap, min_gap * 0.85))
	end)

	T.it("matches Classic and Time Run button edges to the Stats button", function()
		MockEnv.reset_game()
		require("app.core.util.tables")
		require("app.core.util.geometry")
		require("word_game.ui.localize")
		require("word_game.ui.widgets")
		require("word_game.ui.menu")

		G.C.L_BLACK = G.C.L_BLACK or { 0.1, 0.1, 0.1, 1 }
		G.C.BLUE = G.C.BLUE or { 0.2, 0.4, 0.8, 1 }
		G.C.GREEN = G.C.GREEN or { 0.2, 0.7, 0.3, 1 }
		G.C.ORANGE = G.C.ORANGE or { 0.9, 0.5, 0.1, 1 }
		G.C.FILTER = G.C.FILTER or { 0.5, 0.5, 0.5, 1 }
		G.C.RED = G.C.RED or { 0.8, 0.2, 0.2, 1 }
		G.C.UI = G.C.UI or {}
		G.C.UI.TEXT_LIGHT = G.C.UI.TEXT_LIGHT or { 1, 1, 1, 1 }
		G.C.UI.BUTTON_HOVER = G.C.UI.BUTTON_HOVER or { 0.35, 0.35, 0.35, 1 }

		local real_font = alpha_button_font
		alpha_button_font = function()
			return {
				FONT = {
					getWidth = function(_, str) return #(str or "") * 10 end,
					getHeight = function() return 20 end,
				},
				TEXT_HEIGHT_SCALE = 0.7,
				TEXT_OFFSET = { x = 0, y = 0 },
				FONTSCALE = 0.12,
				squish = 1,
			}
		end

		local ui = LayoutView({
			definition = build_main_menu_buttons(),
			config = { align = "cm", major = G.ROOM_ATTACH },
		})
		G.MAIN_MENU_UI = ui
		layout_main_menu_mode_column()
		local edges = main_menu_mode_utility_edge_alignment(ui, { recalculate = false })
		alpha_button_font = real_font
		ui:remove()
		G.MAIN_MENU_UI = nil

		T.assert_not_nil(edges, "Mode and utility button bounds must be measurable")
		local stats = edges.stats
		local classic = edges.classic
		local time_run = edges.time_run
		local tol = 0.02

		T.assert_almost_equal(classic.x, stats.x, tol,
			"Classic left edge should match Stats left edge")
		T.assert_almost_equal(classic.right, stats.right, tol,
			"Classic right edge should match Stats right edge")
		T.assert_almost_equal(time_run.x, stats.x, tol,
			"Time Run left edge should match Stats left edge")
		T.assert_almost_equal(time_run.right, stats.right, tol,
			"Time Run right edge should match Stats right edge")
		T.assert_almost_equal(classic.w, stats.w, tol,
			"Classic width should match Stats width")
		T.assert_almost_equal(time_run.w, stats.w, tol,
			"Time Run width should match Stats width")
	end)

	T.it("wraps Classic and Time Run chrome to button width, not the utility bar width", function()
		MockEnv.reset_game()
		require("app.core.util.tables")
		require("app.core.util.geometry")
		require("word_game.ui.localize")
		require("word_game.ui.widgets")
		require("word_game.ui.menu")

		G.C.L_BLACK = G.C.L_BLACK or { 0.1, 0.1, 0.1, 1 }
		G.C.BLUE = G.C.BLUE or { 0.2, 0.4, 0.8, 1 }
		G.C.GREEN = G.C.GREEN or { 0.2, 0.7, 0.3, 1 }
		G.C.ORANGE = G.C.ORANGE or { 0.9, 0.5, 0.1, 1 }
		G.C.FILTER = G.C.FILTER or { 0.5, 0.5, 0.5, 1 }
		G.C.RED = G.C.RED or { 0.8, 0.2, 0.2, 1 }
		G.C.UI = G.C.UI or {}
		G.C.UI.TEXT_LIGHT = G.C.UI.TEXT_LIGHT or { 1, 1, 1, 1 }
		G.C.UI.BUTTON_HOVER = G.C.UI.BUTTON_HOVER or { 0.35, 0.35, 0.35, 1 }

		local real_font = alpha_button_font
		alpha_button_font = function()
			return {
				FONT = {
					getWidth = function(_, str) return #(str or "") * 10 end,
					getHeight = function() return 20 end,
				},
				TEXT_HEIGHT_SCALE = 0.7,
				TEXT_OFFSET = { x = 0, y = 0 },
				FONTSCALE = 0.12,
				squish = 1,
			}
		end

		local ui = LayoutView({
			definition = build_main_menu_buttons(),
			config = { align = "cm", major = G.ROOM_ATTACH },
		})
		local widths = main_menu_chrome_widths(ui)
		alpha_button_font = real_font
		ui:remove()

		T.assert_not_nil(widths, "Chrome widths must be measurable")
		T.assert_true(widths.util > widths.mode * 1.5,
			"Utility bar should be wider than the mode button stack")
		T.assert_true(widths.mode < 4.5,
			"Mode chrome should hug the buttons, not span the title screen")
	end)

	T.it("keeps Jumbalaya title clear of menu buttons across viewport sizes", function()
		MockEnv.reset_game()
		require("app.core.util.tables")
		require("app.core.util.geometry")
		require("word_game.ui.localize")
		require("word_game.ui.widgets")
		require("word_game.ui.menu")

		G.C.L_BLACK = G.C.L_BLACK or { 0.1, 0.1, 0.1, 1 }
		G.C.BLUE = G.C.BLUE or { 0.2, 0.4, 0.8, 1 }
		G.C.GREEN = G.C.GREEN or { 0.2, 0.7, 0.3, 1 }
		G.C.ORANGE = G.C.ORANGE or { 0.9, 0.5, 0.1, 1 }
		G.C.FILTER = G.C.FILTER or { 0.5, 0.5, 0.5, 1 }
		G.C.RED = G.C.RED or { 0.8, 0.2, 0.2, 1 }
		G.C.UI = G.C.UI or {}
		G.C.UI.TEXT_LIGHT = G.C.UI.TEXT_LIGHT or { 1, 1, 1, 1 }
		G.C.UI.BUTTON_HOVER = G.C.UI.BUTTON_HOVER or { 0.35, 0.35, 0.35, 1 }
		G.STAGE = G.STAGES.MAIN_MENU

		local real_font = alpha_button_font
		alpha_button_font = function()
			return {
				FONT = {
					getWidth = function(_, str) return #(str or "") * 10 end,
					getHeight = function() return 20 end,
				},
				TEXT_HEIGHT_SCALE = 0.7,
				TEXT_OFFSET = { x = 0, y = 0 },
				FONTSCALE = 0.12,
				squish = 1,
			}
		end

		local function min_title_gap_tiles()
			return main_menu_title_menu_gap_px() / ((G.TILESIZE or 20) * (G.TILESCALE or 1))
		end

		local function assert_layout_for_viewport(label, tile_w, tile_h, tilescale)
			G.TILE_W = tile_w
			G.TILE_H = tile_h
			G.TILESIZE = 20
			G.TILESCALE = tilescale
			G.ROOM_ATTACH.T.w = tile_w
			G.ROOM_ATTACH.T.h = tile_h

			G.title_top = {
				T = { x = 0, y = 0, w = 1, h = 1 },
				VT = { x = 0, y = 0, w = 1, h = 1 },
				snap_VT = function() end,
				hard_set_T = function(self, x, y, w, h)
					self.T.x, self.T.y, self.T.w, self.T.h = x, y, w, h
				end,
			}

			local ui = LayoutView({
				definition = build_main_menu_buttons(),
				config = {
					align = "bmi",
					offset = { x = 0, y = main_menu_bottom_offset() },
					major = G.ROOM_ATTACH,
					bond = "Weak",
				},
			})
			G.MAIN_MENU_UI = ui
			layout_main_menu()

			local gap = main_menu_layout_gap()
			local min_gap = min_title_gap_tiles()
			T.assert_not_nil(gap, label .. ": layout gap should be measurable")
			T.assert_true(gap >= min_gap * 0.9,
				string.format("%s: title/menu gap %.3f tiles below minimum %.3f", label, gap, min_gap))

			local layout = main_menu_resolve_logo_layout(ui.T.h)
			T.assert_true(layout.gap >= min_gap * 0.9,
				string.format("%s: resolved layout gap %.3f below minimum %.3f", label, layout.gap, min_gap))

			ui:remove()
			G.MAIN_MENU_UI = nil
			G.title_top = nil
		end

		assert_layout_for_viewport("desktop 1280x720", 20, 11.5, 3.65)
		assert_layout_for_viewport("narrow phone", 20, 11.5, 2.2)
		assert_layout_for_viewport("short screen", 20, 9, 2.5)
		assert_layout_for_viewport("tablet scale", 20, 11.5, 2.8)

		alpha_button_font = real_font
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

	T.it("keeps the title garden zoom and pans within the extra crop", function()
		MockEnv.reset_game()
		require("app.core.util.tables")
		require("app.core.util.geometry")
		require("word_game.ui.localize")
		require("word_game.ui.widgets")
		require("word_game.ui.menu")

		G.ROOM = G.ROOM or {}
		G.ROOM.T = { x = 0, y = 0, w = 20, h = 11 }
		local w, h = title_garden_sprite_dims(G.ROOM.T)
		T.assert_equal(w, 80, "Title garden sprite width should stay room + 60")
		T.assert_equal(h, 33, "Title garden sprite height should stay room + 22")

		local x0, y0 = title_garden_pan_offset(0)
		T.assert_equal(x0, 0, "Pan should start at the current centered crop")
		T.assert_equal(y0, 0, "Pan should start at the current centered crop")

		local extra_x = (w - G.ROOM.T.w) * 0.5
		local extra_y = (h - G.ROOM.T.h) * 0.5
		for t = 0, 200, 2.5 do
			local x, y = title_garden_pan_offset(t)
			T.assert_true(math.abs(x) <= extra_x - 0.5,
				"Horizontal pan should stay inside the zoomed crop")
			T.assert_true(math.abs(y) <= extra_y - 0.5,
				"Vertical pan should stay inside the zoomed crop")
		end

		local x1, y1 = title_garden_pan_offset(12)
		T.assert_true(math.abs(x1) > 0.5 or math.abs(y1) > 0.5,
			"Pan offset should move away from center over time")
	end)

	T.it("slides the title garden splash offset each frame", function()
		MockEnv.reset_game()
		require("app.core.util.tables")
		require("app.core.util.geometry")
		require("word_game.ui.localize")
		require("word_game.ui.widgets")
		require("word_game.ui.menu")

		G.SPLASH_BACK = {
			title_garden_pan = { t = 0 },
			alignment = { offset = { x = 0, y = 0 } },
		}
		update_title_garden_pan(12)
		local x, y = title_garden_pan_offset(12)
		T.assert_almost_equal(G.SPLASH_BACK.alignment.offset.x, x, 0.0001)
		T.assert_almost_equal(G.SPLASH_BACK.alignment.offset.y, y, 0.0001)
		T.assert_almost_equal(G.SPLASH_BACK.title_garden_pan.t, 12, 0.0001)
		T.assert_true(math.abs(x) > 0.01 or math.abs(y) > 0.01,
			"A 12s step should move the garden image")
	end)
end)
