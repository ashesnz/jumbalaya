--[[ tests/unit/test_main_menu_splash_open.lua
     Splash main menu defers MAIN_MENU_UI until the logo dissolve schedule. ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local shell = require("jumbalaya-engine.shell")
local open = require("word_game.ui.menu.animate.open")
local MenuEffects = require("word_game.ui.effects.menu")

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

local function prepare_splash_open()
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
	game.STATES = game.STATES or { MENU = 2 }
	game.STAGES = game.STAGES or { MAIN_MENU = 1, RUN = 2 }

	local enqueued = {}
	game.TIMELINE = {
		enqueue = function(_, tween)
			if type(tween) ~= "table" then
				return
			end
			table.insert(enqueued, tween)
			if tween.mode == "instant" and type(tween.func) == "function" then
				tween.func()
			end
		end,
	}
	function game:prep_stage(new_stage, new_state)
		self.STAGE = new_stage
		self.STATE = new_state
	end
	return game, enqueued
end

T.describe("main menu splash open", function()
	T.it("open_main_menu('splash') does not build MAIN_MENU_UI synchronously", function()
		local game, enqueued = prepare_splash_open()

		local set_main_ui_calls = 0
		local original_set_main_ui = MenuEffects.set_main_ui
		MenuEffects.set_main_ui = function(...)
			set_main_ui_calls = set_main_ui_calls + 1
			return original_set_main_ui(...)
		end

		open.open_main_menu(game, "splash")

		MenuEffects.set_main_ui = original_set_main_ui

		T.assert_nil(game.MAIN_MENU_UI, "MAIN_MENU_UI stays nil until dissolve schedule")
		T.assert_equal(set_main_ui_calls, 0, "set_main_ui is not invoked during open_main_menu")

		local deferred_ui = nil
		for _, tween in ipairs(enqueued) do
			if tween.mode == "delayed" and tween.delay == 4.05 and type(tween.func) == "function" then
				deferred_ui = tween
				break
			end
		end
		T.assert_not_nil(deferred_ui, "set_main_ui is scheduled on the 4.05s splash dissolve lane")
	end)
end)