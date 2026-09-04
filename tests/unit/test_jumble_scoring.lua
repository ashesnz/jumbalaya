--[[ tests/unit/test_jumble_scoring.lua
     Scoring, odometer, and points-to-get tests for jumble mode.
]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("Jumble scoring and odometer", function()
	mock_env.reset_game()
	local jumble = require("word_game.model.jumble")

	T.it("scores word by letter count and ramps multiplier by 0.2x for subsequent plays on same puzzle", function()
		local wr = {
			mode = "jumble",
			jumble = {
				puzzle_index = 1,
				solved = false,
				puzzle_points = 0,
				puzzle_multi = 1.0,
				puzzle_words = {},
				slots = {},
				puzzle = { span = { "C", "T" }, min = 3, max = 7, kind = "span" },
			},
		}
		G.GAME.word_round = wr

		local old_p1, new_p1, old_m1, new_m1 = jumble.record_puzzle_word("CAT")
		T.assert_equal(old_p1, 0)
		T.assert_equal(new_p1, 3, "CAT should give 3 points")
		T.assert_almost_equal(old_m1, 1.0, 0.01)
		T.assert_almost_equal(new_m1, 1.0, 0.01, "First word multi should be 1.0x")

		local old_p2, new_p2, old_m2, new_m2 = jumble.record_puzzle_word("CENT")
		T.assert_equal(old_p2, 3)
		T.assert_equal(new_p2, 7, "CENT adds 4 points to 3 = 7 points")
		T.assert_almost_equal(old_m2, 1.0, 0.01)
		T.assert_almost_equal(new_m2, 1.2, 0.01, "Second word multi should be 1.2x")

		local old_p3, new_p3, old_m3, new_m3 = jumble.record_puzzle_word("CHAT")
		T.assert_equal(old_p3, 7)
		T.assert_equal(new_p3, 11, "CHAT adds 4 points to 7 = 11 points")
		T.assert_almost_equal(old_m3, 1.2, 0.01)
		T.assert_almost_equal(new_m3, 1.4, 0.01, "Third word multi should be 1.4x")

		local old_p4, new_p4, old_m4, new_m4 = jumble.record_puzzle_word("COT")
		T.assert_equal(old_p4, 11)
		T.assert_equal(new_p4, 14, "COT adds 3 points to 11 = 14 points")
		T.assert_almost_equal(old_m4, 1.4, 0.01)
		T.assert_almost_equal(new_m4, 1.6, 0.01, "Fourth word multi should be 1.6x")
	end)

	T.it("calculates total puzzle score as math.floor(points * multi) on advance", function()
		local flow = require("word_game.model.jumble_play")

		local wr = {
			target = 100,
			mode = "jumble",
			jumble = {
				puzzle_index = 1,
				solved = true,
				total_score = 0,
				puzzle_points = 15,
				puzzle_multi = 1.6,
				puzzle_words = { "CAT", "CENT", "CHAT", "COT" },
				slots = {
					{ kind = "fixed", letter = "C" },
					{ kind = "span", cards = {}, min = 1, max = 5 },
					{ kind = "fixed", letter = "T" },
				},
				puzzle = { span = { "C", "T" }, display = "C…T", min = 3, max = 7, kind = "span" },
			},
		}
		G.GAME.word_round = wr
		G.GAME.word_score_animating = false

		flow.play_jumble_word()

		T.assert_equal(wr.jumble.total_score, 24, "Total score should be math.floor(15 * 1.6) = 24")

		local wr2 = {
			target = 200,
			mode = "jumble",
			jumble = {
				puzzle_index = 1,
				solved = true,
				total_score = 100,
				puzzle_points = 7,
				puzzle_multi = 1.2,
				puzzle_words = { "CAT", "CENT" },
				slots = {
					{ kind = "fixed", letter = "C" },
					{ kind = "span", cards = {}, min = 1, max = 5 },
					{ kind = "fixed", letter = "T" },
				},
				puzzle = { span = { "C", "T" }, display = "C…T", min = 3, max = 7, kind = "span" },
			},
		}
		G.GAME.word_round = wr2
		G.GAME.word_score_animating = false

		flow.play_jumble_word()
		T.assert_equal(wr2.jumble.total_score, 108, "Total score should be 100 + math.floor(7 * 1.2) = 108")
	end)

	T.it("updates score banner odometer roll states correctly during jumble plays", function()
		local sb = require("word_game.ui.score_banner")
		sb.reset_jumble_score()
		T.assert_equal(sb.jumble_points, 0)
		T.assert_almost_equal(sb.jumble_multi, 1.0, 0.01)

		sb.roll_jumble_score(0, 4, 1.0, 1.2)
		T.assert_not_nil(sb.points_roll, "Points roll should be active")
		T.assert_equal(sb.points_roll.from, 0)
		T.assert_equal(sb.points_roll.to, 4)
		T.assert_not_nil(sb.multi_roll, "Multi roll should be active")
		T.assert_almost_equal(sb.multi_roll.from, 1.0, 0.01)
		T.assert_almost_equal(sb.multi_roll.to, 1.2, 0.01)

		sb.update(sb.ROLL_TIME + 0.05)
		T.assert_nil(sb.points_roll, "Points roll should complete")
		T.assert_nil(sb.multi_roll, "Multi roll should complete")
		T.assert_equal(sb.jumble_points, 4, "Display points should reach 4")
		T.assert_almost_equal(sb.jumble_multi, 1.2, 0.01, "Display multi should reach 1.2")

		sb.reset_jumble_score()
		T.assert_equal(sb.jumble_points, 0)
		T.assert_almost_equal(sb.jumble_multi, 1.0, 0.01)
	end)

	T.it("initializes round target to 25 points for stage 1-1 and 50 points for stage 1-2", function()
		local pcfg = require("word_game.board.config")
		T.assert_equal(pcfg.ANCHOR_PAD_Y_FRAC, 0.078, "Anchor pad frac lowered to 0.078")

		local round_cfg = require("word_game.config.round_config")
		T.assert_equal(round_cfg.hand_target(1, 1), 25, "Stage 1-1 target should be 25 points")
		T.assert_equal(round_cfg.hand_target(1, 2), 50, "Stage 1-2 target should be 50 points")
		T.assert_equal(round_cfg.hand_target(1, 9), 100, "Stage 1-9 target should be 100 points")

		local wr = { target = round_cfg.hand_target(1, 1) }
		jumble.start_hand(wr)
		T.assert_equal(wr.target, 25, "Jumble preserves round_config target on start_hand")
	end)

	T.it("executes fast odometer countdown for points to get in under 0.5s", function()
		local sb = require("word_game.ui.score_banner")
		G.GAME.word_round = { target = 20, jumble = { total_score = 0 } }
		sb.reset_jumble_score()
		T.assert_equal(sb.points_to_get, 20, "Initial remaining should be 20")
		T.assert_equal(sb.points_earned, 0)
		T.assert_equal(sb.points_got, 0)

		sb.roll_points_to_get(20, 15, 0.40)
		T.assert_not_nil(sb.to_get_roll, "to_get_roll active")
		T.assert_equal(sb.to_get_roll.from, 20)
		T.assert_equal(sb.to_get_roll.to, 15)
		T.assert_almost_equal(sb.to_get_roll.dur, 0.40, 0.01)

		sb.update(0.20)
		T.assert_not_nil(sb.to_get_roll, "Roll still active at 50%")

		sb.update(0.25)
		T.assert_nil(sb.to_get_roll, "Roll completed")
		T.assert_equal(sb.points_to_get, 15, "Display points to get reached 15")
	end)

	T.it("decrements points to get odometer when each word is played in jumble mode", function()
		local flow = require("word_game.model.jumble_play")
		local sb = require("word_game.ui.score_banner")
		local rules = require("word_game.model.jumble_play.jumble_rules")
		WORD_GAME.ScoreBanner = sb
		WORD_GAME.Jumble = jumble
		G.GAME.word_round = {
			target = 20,
			mode = "jumble",
			played_words = {},
			jumble = {
				puzzle_index = 1,
				solved = false,
				total_score = 0,
				puzzle_points = 0,
				puzzle_multi = 1.0,
				puzzle_words = {},
				slots = {
					{ kind = "fixed", letter = "C" },
					{ kind = "blank", card = { ability = { letter = "A" } } },
					{ kind = "fixed", letter = "T" },
				},
				puzzle = "C_T",
			},
		}
		G.GAME.word_score_animating = false
		sb.reset_jumble_score()
		T.assert_equal(sb.points_to_get, 17, "Placed CAT should preview 3 points toward the target")
		T.assert_equal(sb.points_earned, 0)
		T.assert_equal(sb.points_got, 3)
		T.assert_equal(rules.remaining_to_target(G.GAME.word_round.jumble, 20), 17)
		local feedback
		local original_attention_text = spawn_attention
		spawn_attention = function(config)
			feedback = config.text
		end

		local word, err = jumble.validate_current()
		T.assert_equal(word, "CAT", "Validation error: " .. tostring(err))
		flow.play_jumble_word()
		sb.update(0.5)
		T.assert_equal(sb.points_to_get, 17, "Remaining should stay at 17 after scoring CAT")
		T.assert_equal(sb.points_earned, 3)
		T.assert_equal(sb.points_got, 0)

		G.GAME.word_round.target = 100
		G.GAME.word_round.jumble.solved = true
		G.GAME.word_round.jumble.puzzle_points = 4
		G.GAME.word_round.jumble.puzzle_multi = 6
		G.GAME.word_round.jumble.total_score = 0
		G.GAME.word_round.jumble.slots[2].card = nil
		sb.sync_points_to_get_preview(false)
		T.assert_equal(sb.points_to_get, 76, "Committed puzzle score should count before banking")
		flow.play_jumble_word()
		spawn_attention = original_attention_text
		T.assert_equal(feedback, "24 Points Scored!", "Jumble score feedback should show points scored")
	end)

	T.it("updates points to get when placement cards change", function()
		local sb = require("word_game.ui.score_banner")
		local placement_word = require("word_game.model.placement_word")
		WORD_GAME.ScoreBanner = sb
		WORD_GAME.Jumble = jumble
		G.GAME.word_round = {
			target = 25,
			mode = "jumble",
			played_words = {},
			jumble = {
				total_score = 5,
				puzzle_points = 0,
				puzzle_multi = 1.0,
				puzzle_words = {},
				slots = {
					{ kind = "fixed", letter = "C" },
					{ kind = "blank", card = nil },
					{ kind = "fixed", letter = "T" },
				},
				puzzle = "C_T",
			},
		}
		sb.reset_jumble_score()
		T.assert_equal(sb.points_to_get, 20, "No placement should use banked score only")
		T.assert_equal(sb.points_earned, 5)
		T.assert_equal(sb.points_got, 0)

		G.GAME.word_round.jumble.slots[2].card = { ability = { letter = "A" } }
		placement_word.refresh_from_jumble_slots(G.GAME.word_round.jumble.slots)
		sb.update(0.2)
		T.assert_equal(sb.points_to_get, 17, "Valid placed word should preview its puzzle points")
		T.assert_equal(sb.points_earned, 5)
		T.assert_equal(sb.points_got, 3)
		T.assert_equal(sb.format_score_equation(), "5 Earnt + 3 = 17 Remaining")
	end)

	T.it("previews remaining from placed letters even when the word is invalid", function()
		local sb = require("word_game.ui.score_banner")
		local placement_word = require("word_game.model.placement_word")
		local rules = require("word_game.model.jumble_play.jumble_rules")
		WORD_GAME.ScoreBanner = sb
		WORD_GAME.Jumble = jumble
		G.GAME.word_round = {
			target = 25,
			mode = "jumble",
			played_words = {},
			jumble = {
				total_score = 0,
				puzzle_points = 0,
				puzzle_multi = 1.0,
				puzzle_words = {},
				slots = {
					{ kind = "fixed", letter = "C" },
					{ kind = "blank", card = { ability = { letter = "X" } } },
					{ kind = "fixed", letter = "T" },
				},
				puzzle = "C_T",
			},
		}
		sb.reset_jumble_score()
		placement_word.refresh_from_jumble_slots(G.GAME.word_round.jumble.slots)
		sb.update(0.2)
		T.assert_false(G.GAME.placement_word_valid, "Invalid words stay invalid until play")
		T.assert_equal(sb.points_got, 3, "Invalid CXT should still preview 3 points")
		T.assert_equal(rules.remaining_to_target(G.GAME.word_round.jumble, 25), 22)
	end)
end)
