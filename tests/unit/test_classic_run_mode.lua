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
end)
