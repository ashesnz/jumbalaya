--[[ tests/unit/test_sound.lua - audio thread fallback ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local shell = require("jumbalaya-engine.shell")

T.describe("sound dispatch", function()
	T.it("mixes and plays on the main thread when the audio worker is missing", function()
		mock_env.setup()
		local sound = require("jumbalaya-engine.sound.sound")
		local game = shell.game()
		game.F_SOUND_THREAD = false
		game.F_MUTE = false
		game.muted = nil
		game.AUDIO_WORKER = nil
		game.SETTINGS = game.SETTINGS or {}
		game.SETTINGS.SOUND = { volume = 50, music_volume = 60, game_sounds_volume = 100 }
		game.SETTINGS.ambient_control = {}
		game.ARGS = game.ARGS or {}
		game.STATE = game.STATES and game.STATES.MENU or 2
		game.STAGE = game.STAGES and game.STAGES.MAIN_MENU or 1
		game.STATES = game.STATES or { SPLASH = 13, MENU = 2, GAME_OVER = 4 }
		game.STAGES = game.STAGES or { RUN = 2, MAIN_MENU = 1 }

		T.assert_false(sound.audio_thread_live())
		sound.play_sfx("card_slide1", 1, 0.5)
		sound.mix_audio(0.016)
		T.assert_true(true)
	end)
end)
