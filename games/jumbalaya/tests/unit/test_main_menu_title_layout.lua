--[[ tests/unit/test_main_menu_title_layout.lua
     Title tile stays centred on first open and after Classic return. ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local shell = require("jumbalaya-engine.shell")
local layout = require("word_game.ui.menu.layout")
local open = require("word_game.ui.menu.animate.open")
local MenuEffects = require("word_game.ui.effects.menu")

local function copy_rect(node)
	if not node or not node.T then
		return nil
	end
	return { x = node.T.x, y = node.T.y, w = node.T.w, h = node.T.h }
end

local function assert_rects_equal(actual, expected, label)
	T.assert_not_nil(actual, label .. " should have a rect")
	T.assert_not_nil(expected, label .. " expected rect")
	T.assert_almost_equal(actual.x, expected.x, 0.0001, label .. " x")
	T.assert_almost_equal(actual.y, expected.y, 0.0001, label .. " y")
	T.assert_almost_equal(actual.w, expected.w, 0.0001, label .. " w")
	T.assert_almost_equal(actual.h, expected.h, 0.0001, label .. " h")
end

local function fill_menu_colours(game)
	game.C = game.C or {}
	game.C.CLEAR = game.C.CLEAR or { 0, 0, 0, 0 }
	game.C.WHITE = game.C.WHITE or { 1, 1, 1, 1 }
	game.C.L_BLACK = game.C.L_BLACK or { 0, 0, 0, 1 }
	game.C.BLUE = game.C.BLUE or { 0.2, 0.5, 1, 1 }
	game.C.GREEN = game.C.GREEN or { 0, 1, 0, 1 }
	game.C.ORANGE = game.C.ORANGE or { 1, 0.5, 0, 1 }
	game.C.RED = game.C.RED or { 1, 0, 0, 1 }
	game.C.UI = game.C.UI or {}
	game.C.UI.TRANSPARENT_DARK = game.C.UI.TRANSPARENT_DARK or { 0, 0, 0, 0.5 }
	game.C.UI.TEXT_LIGHT = game.C.UI.TEXT_LIGHT or { 1, 1, 1, 1 }
	game.C.BACKGROUND = game.C.BACKGROUND or {}
	game.C.BACKGROUND.C = game.C.BACKGROUND.C or { 0, 0, 0, 1 }
	game.C.BACKGROUND.L = game.C.BACKGROUND.L or { 0, 0, 0, 1 }
	game.C.BACKGROUND.D = game.C.BACKGROUND.D or { 0, 0, 0, 1 }
	game.C.BACKGROUND.contrast = game.C.BACKGROUND.contrast or 1
end

local function prepare_menu_open()
	mock_env.reset_game()
	mock_env.ensure_card_class()
	require("word_game.ui.widgets.buttons")
	require("word_game.ui.menu")

	local game = shell.game()
	fill_menu_colours(game)
	game.TILESIZE = game.TILESIZE or 20
	game.TILESCALE = game.TILESCALE or 1
	game.TILE_W = game.TILE_W or 20
	game.TILE_H = game.TILE_H or 11
	game.VERSION = game.VERSION or "test"
	game.SETTINGS = game.SETTINGS or {}
	game.SETTINGS.GRAPHICS = game.SETTINGS.GRAPHICS or { shadows = "Off" }
	game.LETTERS = game.LETTERS or {}
	game.LETTERS.centers = game.LETTERS.centers or {}
	game.LETTERS.centers.deck_alpha = game.LETTERS.centers.deck_alpha or { name = "alpha", pos = 1 }
	game.INPUT = game.INPUT or {}
	game.INPUT.locks = game.INPUT.locks or {}
	game.INPUT.lock_input = false
	game.LIVE = game.LIVE or {}
	game.LIVE.SPRITE = game.LIVE.SPRITE or {}
	game.LIVE.CARDAREA = game.LIVE.CARDAREA or {}
	game.MAIN_MENU_UI = nil
	game.title_top = nil
	game.SPLASH_LOGO = nil
	game.SPLASH_FRONT = nil
	game.TIMELINE = {
		enqueue = function(_, tween)
			if type(tween) == "table" and type(tween.func) == "function" then
				tween.func()
			end
		end,
	}
	function game:prep_stage(new_stage, new_state)
		self.STAGE = new_stage
		self.STATE = new_state
	end
	return game
end

local function expected_logo_layout(game)
	local menu_h = game.MAIN_MENU_UI and game.MAIN_MENU_UI.T and game.MAIN_MENU_UI.T.h or 0
	return layout.main_menu_resolve_logo_layout(menu_h)
end

T.describe("main menu title layout", function()
	T.it("layout_main_menu centres the title when MAIN_MENU_UI is missing", function()
		mock_env.reset_game()
		require("word_game.ui.menu")
		local game = shell.game()
		game.TILE_W = 20
		game.TILE_H = 11
		game.TILESIZE = 20
		game.TILESCALE = 1
		game.MAIN_MENU_UI = nil
		game.title_top = {
			T = { x = 0, y = 0, w = 1, h = 1.4 },
			snap_drawn = function() end,
		}

		layout.layout_main_menu()

		local expected = layout.main_menu_resolve_logo_layout(0)
		T.assert_almost_equal(game.title_top.T.x, expected.x, 0.0001, "title x")
		T.assert_almost_equal(expected.x, game.TILE_W / 2 - expected.w / 2, 0.0001, "centred formula")
		T.assert_almost_equal(game.title_top.T.y, expected.y, 0.0001, "title y")
		T.assert_almost_equal(game.title_top.T.w, expected.w, 0.0001, "title w")
		T.assert_almost_equal(game.title_top.T.h, expected.h, 0.0001, "title h")
		T.assert_not_equal(game.title_top.T.x, 0, "title must leave origin")
	end)

	T.it("open_main_menu and open_main_menu('game') share the centred title rect", function()
		local first = prepare_menu_open()
		open.open_main_menu(first)
		local first_title = copy_rect(first.title_top)
		local first_logo = copy_rect(first.SPLASH_LOGO)
		local first_layout = expected_logo_layout(first)
		T.assert_not_nil(first_title, "first-open title_top")
		T.assert_almost_equal(first_title.x, first_layout.x, 0.0001, "first-open title x")
		T.assert_almost_equal(first_layout.x, first.TILE_W / 2 - first_layout.w / 2, 0.0001)
		assert_rects_equal(first_title, {
			x = first_layout.x,
			y = first_layout.y,
			w = first_layout.w,
			h = first_layout.h,
		}, "first-open title_top")
		assert_rects_equal(first_logo, first_title, "first-open SPLASH_LOGO")

		local returned = prepare_menu_open()
		open.open_main_menu(returned, "game")
		T.assert_not_nil(returned.MAIN_MENU_UI, "game-open MAIN_MENU_UI")
		local returned_title = copy_rect(returned.title_top)
		local returned_logo = copy_rect(returned.SPLASH_LOGO)
		local returned_layout = expected_logo_layout(returned)
		T.assert_not_nil(returned_title, "return-from-Classic title_top")
		T.assert_almost_equal(returned_title.x, returned_layout.x, 0.0001, "return title x")
		T.assert_almost_equal(returned_layout.x, returned.TILE_W / 2 - returned_layout.w / 2, 0.0001)
		assert_rects_equal(returned_title, first_title, "title_top after Classic return")
		assert_rects_equal(returned_logo, first_logo, "SPLASH_LOGO after Classic return")
	end)

	T.it("open_main_menu('game') centres the title before MAIN_MENU_UI exists", function()
		local game = prepare_menu_open()
		local orig_set_main_ui = MenuEffects.set_main_ui
		MenuEffects.set_main_ui = function() end
		open.open_main_menu(game, "game")
		MenuEffects.set_main_ui = orig_set_main_ui

		T.assert_nil(game.MAIN_MENU_UI)
		T.assert_not_nil(game.title_top)
		local expected = layout.main_menu_resolve_logo_layout(0)
		T.assert_almost_equal(game.title_top.T.x, expected.x, 0.0001)
		T.assert_almost_equal(expected.x, game.TILE_W / 2 - expected.w / 2, 0.0001)
		T.assert_not_equal(game.title_top.T.x, 0)
		if game.SPLASH_LOGO and game.SPLASH_LOGO.T then
			T.assert_almost_equal(game.SPLASH_LOGO.T.x, expected.x, 0.0001)
		end
	end)
end)
