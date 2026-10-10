--[[ tests/unit/test_boss_intro_display.lua - Boss intro ribbons and countdown overlay ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local shell = require("jumbalaya-engine.shell")

T.describe("boss intro display", function()
	T.it("hides score chips in boss_prep without sliding the stage ribbon", function()
		mock_env.reset_game()
		mock_env.patch_game({
			word_round = { set = 1, hand_index = 3, target = 2, jumble = { total_score = 2 } },
		})
		local announce = require("word_game.ui.score_banner.boss_announce")
		announce.clear()
		local sb = require("word_game.ui.score_banner")
		sb.set_banner_mode("boss_prep")
		T.assert_false(announce.is_active())
		local hud = sb.state()
		T.assert_equal(hud.banner_mode, "boss_prep")
	end)

	T.it("shows the stage ribbon as soon as boss_word mode is set", function()
		mock_env.reset_game()
		local announce = require("word_game.ui.score_banner.boss_announce")
		announce.clear()
		local sb = require("word_game.ui.score_banner")
		sb.set_banner_mode("boss_word")
		T.assert_true(announce.is_active())
	end)

	T.it("plays a single combined banner when boss_word mode begins", function()
		mock_env.reset_game()
		mock_env.patch_game({
			word_round = { set = 1, hand_index = 3, target = 2, jumble = { total_score = 2 } },
		})
		local announce = require("word_game.ui.score_banner.boss_announce")
		announce.clear()
		local sb = require("word_game.ui.score_banner")
		sb.set_banner_mode("boss_word")
		T.assert_true(announce.is_active())
		T.assert_equal(announce.stage_message(), "Boss Stage — Garden Theme")
	end)

	T.it("routes boss countdown through the center overlay", function()
		mock_env.reset_game()
		_G.WORD_GAME_UI = _G.WORD_GAME_UI or {}
		_G.WORD_GAME_UI.BossWordAnnounce = require("word_game.ui.score_banner.boss_announce")
		local announce = _G.WORD_GAME_UI.BossWordAnnounce
		announce.clear()
		local word_feedback = require("word_game.ui.feedback.word_feedback")
		word_feedback.show_boss_countdown("3", 0.85)
		T.assert_true(announce.has_center_overlay())
	end)

	T.it("draws center countdown text in the HUD pass", function()
		mock_env.reset_game()
		local game = shell.game()
		game.STATE = game.STATES.TABLE_BOARD
		game.ROOM = game.ROOM or { T = { x = 0, y = 0, w = 20, h = 11 } }
		game.ROOM.translate_container = game.ROOM.translate_container or function() end
		game.TILESCALE = 1
		game.TILESIZE = 20
		game.TIMERS = game.TIMERS or { REAL = 0 }

		mock_env.patch_game({
			word_round = {
				set = 1,
				hand_index = 3,
				jumble = { boss_word_staging = true },
			},
		})

		local announce = require("word_game.ui.score_banner.boss_announce")
		announce.clear()
		announce.set_center_text("GO!", 1.0, "countdown")

		local painted = false
		local orig_print = love.graphics.print
		love.graphics.print = function(text)
			if text == "GO!" then
				painted = true
			end
		end

		announce.draw()
		love.graphics.print = orig_print

		T.assert_true(painted, "boss center overlay must paint countdown digits")
	end)

	T.it("keeps the stage ribbon between the timer and score banner rects", function()
		mock_env.reset_game()
		local game = shell.game()
		game.STATE = game.STATES.TABLE_BOARD
		game.ROOM = game.ROOM or { T = { x = 0, y = 0, w = 20, h = 11 } }
		game.TILESCALE = 1
		game.TILESIZE = 20

		local measure = require("word_game.ui.score_banner.boss_announce").measure_stack()
		T.assert_not_nil(measure)
		T.assert_true(measure.fits_above_score, "ribbon must stay in the HUD slot above the score banner")
		T.assert_true(measure.bottom <= measure.score_top)
		T.assert_true(measure.top >= measure.timer_bottom)
	end)

	T.it("skips hand-clear celebration when advancing into the boss word", function()
		mock_env.reset_game()
		mock_env.install_presentation()
		mock_env.install_hand_clear()
		local play = require("word_game.model.jumble_play")
		mock_env.patch_game({
			word_round = {
				set = 1,
				hand_index = 3,
				target = 2,
				jumble = { total_score = 2, boss_word_active = false },
			},
		})

		local began = false
		local Jumble = require("word_game.model.jumble")
		local orig = Jumble.begin_boss_word
		Jumble.begin_boss_word = function(...)
			began = true
			return true
		end

		play.on_hand_cleared()
		Jumble.begin_boss_word = orig

		T.assert_true(began, "boss_next hand clear should begin boss intro immediately")
	end)
end)
