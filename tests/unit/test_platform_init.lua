--[[ tests/unit/test_platform_init.lua
     Unit tests for Game:define_constants platform-specific settings and mobile initialization.
]]

local T = require("tests.framework")
local MockEnv = require("tests.helpers.mock_env")
local Runtime = require("app.effects.runtime")

T.describe("Platform and Globals Initialization", function()
	local orig_getOS = love.system and love.system.getOS
	local orig_HEX = _G.HEX

	-- Ensure HEX helper exists for define_constants if not present in mock env
	_G.HEX = _G.HEX or function(hex)
		return { 1, 1, 1, 1 }
	end

	-- Ensure engine helpers, Kind and Game exist
	require("app.core.util.tables")
	require("app.core.util.geometry")
	require("app.core.object")
	require("word_game.model.game")

	-- Load globals definition
	local ok, err = pcall(require, "word_game.model.globals")

	local function setup_game_for_os(os_name)
		love.system = love.system or {}
		love.system.getOS = function() return os_name end
		local game = setmetatable({}, Game)
		game:define_constants()
		return game
	end

	T.it("initializes cleanly on iOS without nil SETTINGS indexing", function()
		local game = setup_game_for_os("iOS")

		T.assert_not_nil(game.SETTINGS, "SETTINGS must be initialized on iOS")
		T.assert_not_nil(game.SETTINGS.GRAPHICS, "SETTINGS.GRAPHICS must be initialized on iOS")
		T.assert_not_nil(game.SETTINGS.WINDOW, "SETTINGS.WINDOW must be initialized on iOS")

		T.assert_equal(game.F_SOUND_THREAD, false, "F_SOUND_THREAD should be false on iOS to avoid audio thread issues")
		T.assert_equal(game.F_VERBOSE, false, "F_VERBOSE should be false on iOS")
		T.assert_equal(game.SETTINGS.GRAPHICS.texture_scaling, 1, "iOS should use 1x texture scaling to minimize memory footprint")
		T.assert_equal(game.SETTINGS.GRAPHICS.crt, 0, "iOS should disable CRT post-processing")
		T.assert_equal(game.SETTINGS.WINDOW.screenmode, "Borderless", "iOS should use Borderless window mode")
		T.assert_equal(game.SETTINGS.WINDOW.selected_display, 1, "iOS should select display 1")
	end)

	T.it("initializes cleanly on Android with mobile defaults", function()
		local game = setup_game_for_os("Android")

		T.assert_not_nil(game.SETTINGS, "SETTINGS must be initialized on Android")
		T.assert_equal(game.F_SOUND_THREAD, false, "F_SOUND_THREAD should be false on Android")
		T.assert_equal(game.SETTINGS.GRAPHICS.texture_scaling, 1, "Android should use 1x texture scaling")
		T.assert_equal(game.SETTINGS.WINDOW.screenmode, "Borderless", "Android should use Borderless screenmode")
	end)

	T.it("initializes desktop settings on Windows and OS X", function()
		local game_win = setup_game_for_os("Windows")
		T.assert_equal(game_win.F_DISCORD, true, "Discord should be enabled on Windows")
		T.assert_equal(game_win.F_CRASH_REPORTS, true, "Crash reports should be enabled on Windows")
		T.assert_equal(game_win.SETTINGS.GRAPHICS.texture_scaling, 2, "Default desktop texture scaling should be 2")

		local game_osx = setup_game_for_os("OS X")
		T.assert_equal(game_osx.F_DISCORD, true, "Discord should be enabled on OS X")
		T.assert_equal(game_osx.F_CRASH_REPORTS, false, "Crash reports should be disabled on OS X")
	end)

	T.it("ensures mix_audio and update_canvas_juice run safely during early startup", function()
		require("app.core.audio.sound")
		require("app.effects")

		_G.G = setmetatable({}, Game)
		_G.G:define_constants()
		_G.G.TIMERS = { REAL = 0 }
		_G.G.ARGS = {}

		-- G.GAME is nil at initial startup
		_G.G.GAME = nil
		_G.G.ROOM = nil

		local sound_ok = pcall(function()
			mix_audio(0.016)
		end)
		T.assert_true(sound_ok, "mix_audio must not throw error when G.GAME is nil during early boot")

		local canvas_ok = pcall(function()
			Runtime.update_canvas_juice(0.016)
		end)
		T.assert_true(canvas_ok, "update_canvas_juice must not throw error when G.ROOM is nil during early boot")
	end)

	-- Restore original functions
	if orig_getOS then
		love.system.getOS = orig_getOS
	end
	if orig_HEX then
		_G.HEX = orig_HEX
	end
end)
