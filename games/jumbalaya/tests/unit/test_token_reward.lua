--[[ tests/unit/test_token_reward.lua - Stage score → token conversion ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local shell = require("jumbalaya-engine.shell")

local function stub_token_ui()
	WORD_GAME_UI = WORD_GAME_UI or {}
	WORD_GAME_UI.TimelineTimer = {
		is_active = false,
		sync_progress = function() end,
		start_score_roll = function() end,
	}
	WORD_GAME_UI.TableDeck = {
		bump_token_display = function() end,
		sync_token_display = function() end,
		token_center_px = function() return 100, 200 end,
	}
end

local function classic_wr(total_score, puzzle_points, puzzle_multi)
	return {
		set = 1,
		hand_index = 2,
		target = 25,
		mode = "jumble",
		jumble = {
			total_score = total_score or 0,
			puzzle_points = puzzle_points or 0,
			puzzle_multi = puzzle_multi or 1.0,
			puzzle_words = {},
			slots = {},
		},
	}
end

T.describe("token reward", function()
	mock_env.reset_game()

	T.it("counts unbanked puzzle points toward earned tokens (35 banked on a 25 target)", function()
		mock_env.patch_game({
			run_mode = "classic",
			word_round = classic_wr(10, 25, 1.0),
			run_state = { tokens = 0, perks = {}, trade_used_this_hand = false },
		})
		stub_token_ui()
		local capture = require("word_game.ui.table.token_reward.capture")
		local session = require("word_game.ui.table.token_reward.session")
		session.reset()

		capture.capture_reward({ refresh = true })
		T.assert_equal(capture.earned_amount(), 35)
	end)

	T.it("snapshots play result score before the hand commits total_score", function()
		mock_env.patch_game({
			run_mode = "classic",
			word_round = classic_wr(30, 5, 1.0),
			run_state = { tokens = 0, perks = {}, trade_used_this_hand = false },
		})
		stub_token_ui()
		local capture = require("word_game.ui.table.token_reward.capture")
		local session = require("word_game.ui.table.token_reward.session")
		session.reset()

		capture.capture_reward({ refresh = true, score = 35 })
		T.assert_equal(capture.earned_amount(), 35)
	end)

	T.it("grants the full earned amount to run_state after the fly animation", function()
		mock_env.patch_game({
			run_mode = "classic",
			word_round = classic_wr(10, 25, 1.0),
			run_state = { tokens = 0, perks = {}, trade_used_this_hand = false },
		})
		local game = shell.game()
		game.TILESIZE = 20
		game.TILESCALE = 1
		game.ROOM = { T = { w = 20, h = 11, x = 0, y = 0, r = 0 } }
		game.draw_pile = {}
		stub_token_ui()

		local session = require("word_game.ui.table.token_reward.session")
		local flyers = require("word_game.ui.table.token_reward.flyers")
		local state = require("word_game.model.run.state")
		session.reset()

		local done
		T.assert_true(flyers.try_award(function() done = true end))
		for _ = 1, 600 do
			flyers.update(0.05)
			if done then break end
		end
		T.assert_true(done, "token fly sequence should finish")
		T.assert_equal(state.tokens(), 35)
	end)

	T.it("capture on hand clear uses evaluate result score for word plays", function()
		mock_env.patch_game({
			run_mode = "classic",
			word_round = classic_wr(30, 5, 1.0),
			run_state = { tokens = 0, perks = {}, trade_used_this_hand = false },
		})
		stub_token_ui()
		local effects = require("word_game.ui.play_effects")
		local session = require("word_game.ui.table.token_reward.session")
		local capture = require("word_game.ui.table.token_reward.capture")
		session.reset()

		effects.capture_token_timer_if_cleared(true, {
			result = { kind = "word_play", cleared = true, new_score = 35 },
		})
		T.assert_equal(capture.earned_amount(), 35)
	end)
end)
