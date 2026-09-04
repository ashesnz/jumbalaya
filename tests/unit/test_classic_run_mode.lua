--[[ tests/unit/test_classic_run_mode.lua - Classic run mode score-to-token rewards ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("Classic run mode", function()
	T.it("awards tokens equal to banked score when a classic hand clears", function()
		mock_env.reset_game()
		G.GAME.run_mode = "classic"
		G.GAME.word_round = {
			set = 1,
			hand_index = 1,
			target = 50,
			jumble = { total_score = 50 },
		}
		local token_reward = require("word_game.ui.token_reward")
		WORD_GAME.TokenReward = token_reward
		token_reward.reset()

		T.assert_true(token_reward.is_eligible(), "Classic should award tokens after every hand")
		token_reward.capture_reward()
		T.assert_equal(token_reward.earned_amount(), 50)
	end)

	T.it("bumps the classic slider and smoke through CAT → CART → CREST then resets on next puzzle", function()
		mock_env.reset_game()
		G.GAME.run_mode = "classic"
		local tt = require("word_game.ui.timeline_timer")
		local jumble = require("word_game.model.jumble")
		local rules = require("word_game.model.play.jumble_rules")
		WORD_GAME.TimelineTimer = tt
		WORD_GAME.Jumble = jumble

		G.GAME.word_round = {
			set = 1,
			hand_index = 1,
			target = 50,
			mode = "jumble",
			played_words = {},
			jumble = {
				total_score = 0,
				puzzle_points = 0,
				puzzle_multi = 1.0,
				puzzle_words = {},
				solved = false,
				slots = {},
			},
		}
		tt.reset_progress(50)

		local function play_word(word)
			local j = G.GAME.word_round.jumble
			local old_pts = j.puzzle_points or 0
			local old_multi = j.puzzle_multi or 1.0
			j.puzzle_words[#j.puzzle_words + 1] = word
			j.puzzle_points = old_pts + #word
			j.solved = true
			local old_score = rules.total_with_puzzle(j, old_pts, old_multi)
			local new_score = rules.total_with_puzzle(j, j.puzzle_points, j.puzzle_multi)
			tt.on_word_played(old_score, new_score)
		end

		play_word("CAT")
		T.assert_false(tt.smoke_active)
		play_word("CART")
		T.assert_false(tt.smoke_active)
		play_word("CREST")
		T.assert_true(tt.smoke_active)

		jumble.apply_puzzle(G.GAME.word_round, { pattern = "_ A R", display = "_ A R" })
		T.assert_false(tt.smoke_active, "New puzzle should stop building combo immediately")
		T.assert_true(tt.display_combo_level() > 0, "Visual smoke should ease out on puzzle change")
		T.assert_equal(#G.GAME.word_round.jumble.puzzle_words, 0)
	end)

	T.it("does not end the hand when the classic target is met", function()
		mock_env.reset_game()
		G.GAME.run_mode = "classic"
		local RunMode = require("word_game.model.run_mode")
		local token_reward = require("word_game.ui.token_reward")
		local effects = require("word_game.ui.play_effects")
		T.assert_false(RunMode.ends_hand_on_target())

		G.GAME.word_round = {
			set = 1,
			hand_index = 1,
			target = 25,
			jumble = { total_score = 30 },
		}
		token_reward.reset()
		local focus_started = false
		local prev_focus = WORD_GAME.HandClearFocus
		WORD_GAME.HandClearFocus = {
			is_eligible = function() return true end,
			begin = function() focus_started = true end,
		}
		effects.capture_token_timer_if_cleared(true)
		WORD_GAME.HandClearFocus = prev_focus
		T.assert_false(focus_started, "Classic should not spotlight-clear when the target is met")
	end)

	T.it("keeps timer-based rewards for Time Run on stage 1-1 only", function()
		mock_env.reset_game()
		G.GAME.run_mode = "time_run"
		G.GAME.word_round = { set = 1, hand_index = 2, target = 2 }
		local token_reward = require("word_game.ui.token_reward")
		token_reward.reset()
		T.assert_false(token_reward.is_eligible(), "Time Run should not award tokens after 1-1")

		G.GAME.word_round.hand_index = 1
		T.assert_true(token_reward.is_eligible(), "Time Run should award tokens on 1-1")
	end)

	T.it("switches the vault button to Next when the classic target is met", function()
		mock_env.reset_game()
		G.GAME.run_mode = "classic"
		G.STATE = G.STATES.TABLE_BOARD
		G.GAME.word_round = {
			set = 1,
			hand_index = 1,
			target = 25,
			jumble = { total_score = 25, puzzle_points = 0, puzzle_multi = 1.0 },
		}
		local tt = require("word_game.ui.timeline_timer")
		local vault_btn = require("word_game.ui.vault_stage_button")
		WORD_GAME.TimelineTimer = tt
		WORD_GAME.VaultStageButton = vault_btn
		tt.reset_progress(25)
		tt.sync_progress()
		T.assert_true(vault_btn.is_next_mode())
	end)

	T.it("allows further play once the classic target is reached", function()
		mock_env.reset_game()
		G.GAME.run_mode = "classic"
		G.STATE = G.STATES.TABLE_BOARD
		G.GAME.word_round = {
			set = 1,
			hand_index = 1,
			target = 25,
			jumble = { total_score = 30, puzzle_points = 0, puzzle_multi = 1.0, slots = {} },
		}
		local RunMode = require("word_game.model.run_mode")
		local rules = require("word_game.model.play.jumble_rules")
		local tt = require("word_game.ui.timeline_timer")
		WORD_GAME.TimelineTimer = tt
		tt.reset_progress(25)
		tt.sync_progress()

		T.assert_true(RunMode.classic_stage_complete())
		T.assert_false(rules.play_blocked(G.GAME.word_round.jumble))
	end)

	T.it("doubles word points after the classic target is already reached", function()
		mock_env.reset_game()
		G.GAME.run_mode = "classic"
		G.GAME.word_round = {
			set = 1,
			hand_index = 1,
			target = 25,
			mode = "jumble",
			played_words = {},
			jumble = {
				total_score = 30,
				puzzle_points = 0,
				puzzle_multi = 1.0,
				puzzle_words = {},
				solved = false,
				slots = {},
			},
		}
		local jumble = require("word_game.model.jumble")
		local rules = require("word_game.model.play.jumble_rules")

		local old_pts, new_pts = jumble.record_puzzle_word("CATS", { used_cards = {} })
		T.assert_equal(new_pts - old_pts, 8, "Four-letter word should double to eight after target")

		G.GAME.word_round.jumble.total_score = 20
		G.GAME.word_round.jumble.puzzle_points = 0
		G.GAME.word_round.jumble.puzzle_words = {}
		local preview = rules.preview_puzzle_total_after_word(
			G.GAME.word_round.jumble, "CATS", {})
		T.assert_equal(preview, 4)

		old_pts, new_pts = jumble.record_puzzle_word("CATS", { used_cards = {} })
		T.assert_equal(new_pts - old_pts, 4, "Word should not double before the target is reached")
	end)

	T.it("doubles banked puzzle totals when the stage was already past target", function()
		mock_env.reset_game()
		G.GAME.run_mode = "classic"
		G.GAME.word_round = {
			set = 1,
			hand_index = 1,
			target = 25,
			mode = "jumble",
			played_words = {},
			jumble = {
				total_score = 30,
				puzzle_points = 5,
				puzzle_multi = 1.0,
				puzzle_words = { "CAT" },
				solved = true,
				slots = {},
			},
		}
		local rules = require("word_game.model.play.jumble_rules")
		local jumble = require("word_game.model.jumble")
		local result = rules.evaluate_play(jumble, G.GAME.word_round.jumble)
		T.assert_equal(result.kind, "bank_puzzle")
		T.assert_equal(result.new_total, 40, "Five puzzle points should double to ten when banking past target")
		T.assert_true(result.post_target_doubled)
	end)

	T.it("shows post-target scoring on the classic timeline slider", function()
		mock_env.reset_game()
		G.GAME.run_mode = "classic"
		local tt = require("word_game.ui.timeline_timer")
		G.GAME.word_round = {
			target = 25,
			jumble = { total_score = 30, puzzle_points = 0, puzzle_multi = 1.0 },
		}
		tt.reset_progress(25)
		tt.sync_progress()
		T.assert_true(tt.post_target_scoring)
		tt.pulse_post_target()
		T.assert_true(tt.post_target_pulse > 0)
	end)

	T.it("floats ×2 off the right end of the slider like Hand Cleared", function()
		mock_env.reset_game()
		G.GAME.run_mode = "classic"
		G.C.GOLD = G.C.GOLD or { 1, 0.8, 0, 1 }
		local play_effects = require("word_game.ui.play_effects")
		local float_up_text = require("word_game.ui.float_up_text")
		local captured
		local original_spawn = float_up_text.spawn
		float_up_text.spawn = function(config)
			captured = config
			return config
		end
		WORD_GAME.FloatUpText = float_up_text

		play_effects.show_post_target_multiplier_fx({ post_target_doubled = true })
		float_up_text.spawn = original_spawn

		T.assert_not_nil(captured, "×2 should use the existing float-up text")
		T.assert_equal(captured.text, "×2")
		T.assert_equal(captured.colour, G.C.GOLD, "×2 should use the same gold as Hand Cleared")
		T.assert_equal(captured.life, 1.8, "×2 should hold then fade like Hand Cleared")

		local layout = require("word_game.ui.layout")
		local rect = layout.timeline_rect()
		local origin = float_up_text.timeline_right_origin(rect, {
			w = captured.w,
			h = captured.h,
		})
		T.assert_almost_equal(captured.x, origin.x, 0.001, "×2 should sit on the slider's right end")
		T.assert_almost_equal(captured.y, origin.y, 0.001)
		local center_x = captured.x + captured.w * 0.5
		T.assert_almost_equal(center_x, rect.x + rect.w, 0.001,
			"×2 center should match the slider's right tip, not the middle")
		T.assert_true(center_x > rect.x + rect.w * 0.75,
			"×2 must stay on the right end of the slider")
	end)

	T.it("shows the proceed hint only when play is pressed with an empty card area", function()
		mock_env.reset_game()
		G.GAME.run_mode = "classic"
		G.STATE = G.STATES.TABLE_BOARD
		G.GAME.word_round = {
			set = 1,
			hand_index = 1,
			target = 25,
			mode = "jumble",
			jumble = { total_score = 32, puzzle_points = 0, puzzle_multi = 1.0, slots = {} },
		}
		G.placement_table = { area = { T = { x = 4, y = 4, w = 10, h = 2 }, cards = {} } }
		G.hand = { T = { x = 3, y = 8, w = 12, h = 2.8 }, cards = {} }
		G.TILE_W = 20
		G.TILE_H = 11.5
		G.ROOM_ATTACH = { T = { x = 0, y = 0, w = 20, h = 11.5 } }
		_G.get_table_felt_rect = _G.get_table_felt_rect or function()
			return { x = 0.8, y = 2.0, w = 15.4, h = 8.0 }
		end
		local RunMode = require("word_game.model.run_mode")
		local placement_controls = require("word_game.ui.placement_controls")
		local HandShuffle = require("word_game.ui.hand_shuffle")
		local tt = require("word_game.ui.timeline_timer")
		WORD_GAME.TimelineTimer = tt
		WORD_GAME.HandShuffle = HandShuffle
		WORD_GAME.Jumble = {
			is_active = function() return true end,
			state = function() return G.GAME.word_round.jumble end,
		}
		tt.reset_progress(25)
		tt.sync_progress()

		T.assert_true(RunMode.classic_stage_complete(), "Score above target should count as reached")
		T.assert_equal(RunMode.classic_proceed_message(), "Target 25 Reached! Click Next to Continue.")

		local captured = nil
		local original_attention = spawn_attention
		spawn_attention = function(args)
			captured = args
		end

		placement_controls.try_play()
		T.assert_not_nil(captured, "Empty card area should show the proceed hint")
		T.assert_equal(captured.text, "Target 25 Reached! Click Next to Continue.")
		T.assert_equal(captured.colour, G.C.RED)

		captured = nil
		G.placement_table.area.cards = { { ability = { letter = "A" } } }
		local played = false
		WORD_GAME.Play = { play_word = function() played = true end }
		placement_controls.try_play()
		T.assert_true(played, "Play with cards in the area should keep scoring after the target is reached")

		spawn_attention = original_attention
	end)

	T.it("styles the proceed hint like Hand Cleared in red", function()
		mock_env.reset_game()
		local RunMode = require("word_game.model.run_mode")
		local word_feedback = require("word_game.ui.word_feedback")

		local captured = nil
		local original_attention = spawn_attention
		spawn_attention = function(args)
			captured = args
		end
		word_feedback.show_classic_proceed()
		spawn_attention = original_attention
		T.assert_not_nil(captured)
		T.assert_equal(captured.text, "Target 25 Reached! Click Next to Continue.")
		T.assert_equal(captured.colour, G.C.RED)
		T.assert_equal(captured.hold, 2.8)
	end)

	T.it("rolls the classic timeline score down during token award", function()
		mock_env.reset_game()
		G.GAME.run_mode = "classic"
		G.STATE = G.STATES.TABLE_BOARD
		G.GAME.word_round = {
			set = 1,
			hand_index = 1,
			target = 25,
			jumble = { total_score = 30 },
		}
		local tt = require("word_game.ui.timeline_timer")
		local token_reward = require("word_game.ui.token_reward")
		WORD_GAME.TimelineTimer = tt
		WORD_GAME.TokenReward = token_reward
		tt.reset_progress(25)
		token_reward.reset()
		token_reward.capture_reward()

		local started = token_reward.try_award(function() end)
		T.assert_true(started)
		T.assert_not_nil(tt.score_roll)
		T.assert_equal(tt.format_progress_label(), "30 / 25")

		tt.update(1)
		T.assert_true((tt.progress_score or 0) < 30)
	end)
end)
