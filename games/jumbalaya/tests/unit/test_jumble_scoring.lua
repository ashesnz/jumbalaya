--[[ tests/unit/test_jumble_scoring.lua
     Scoring, odometer, and points-to-get tests for jumble mode.
]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("Jumble scoring and odometer", function()
	mock_env.reset_game()
	local jumble = require("word_game.model.jumble")

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
		mock_env.patch_game({ word_round = wr, word_score_animating = false })

		require("word_game.ui.play_effects.resolution").resolve(flow)

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
		mock_env.patch_game({ word_round = wr2, word_score_animating = false })

		require("word_game.ui.play_effects.resolution").resolve(flow)
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

	T.it("executes fast odometer countdown for points to get in under 0.5s", function()
		local sb = require("word_game.ui.score_banner")
		mock_env.patch_game({ word_round = { target = 20, jumble = { total_score = 0 } } })
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

	T.it("keeps a points-to-get roll when preview syncs again during play resolution", function()
		local sb = require("word_game.ui.score_banner")
		mock_env.patch_game({
			word_round = {
				target = 20,
				jumble = { total_score = 5, puzzle_points = 0, puzzle_multi = 1.0 },
			},
		})
		sb.reset_jumble_score()
		T.assert_equal(sb.points_to_get, 15)

		mock_env.patch_game({
			word_round = {
				target = 20,
				jumble = { total_score = 5, puzzle_points = 3, puzzle_multi = 1.0 },
			},
		})
		sb.sync_points_to_get_preview(true)
		T.assert_not_nil(sb.to_get_roll, "First PLAY_RESOLVED sync should start a roll")
		sb.sync_points_to_get_preview(true, { remain_dur = 0.4 })
		T.assert_not_nil(sb.to_get_roll, "Second banner sync must not snap the in-flight roll")
		T.assert_equal(sb.to_get_roll.to, 12)
		T.assert_equal(sb.points_to_get, 15, "Displayed remaining should still be rolling from 15")
	end)

	T.it("updates points to get when placement cards change", function()
		local sb = require("word_game.ui.score_banner")
		local placement_word = require("word_game.model.jumble.placement_word")
		WORD_GAME_UI.ScoreBanner = sb
		WORD_GAME.Jumble = jumble
		mock_env.patch_game({
			word_round = {
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
			},
		})
		sb.reset_jumble_score()
		T.assert_equal(sb.points_to_get, 20, "No placement should use banked score only")
		T.assert_equal(sb.points_earned, 5)
		T.assert_equal(sb.points_got, 0)

		mock_env.mutate_game(function(g)
			g.word_round.jumble.slots[2].card = { ability = { letter = "A" } }
		end)
		placement_word.refresh_from_jumble_slots(mock_env.game_state().word_round.jumble.slots)
		sb.sync_points_to_get_preview(true)
		sb.update(0.2)
		T.assert_equal(sb.points_to_get, 17, "Valid placed word should preview its puzzle points")
		T.assert_equal(sb.points_earned, 5)
		T.assert_equal(sb.points_got, 3)
		T.assert_equal(sb.format_score_equation(), "5 Earnt + 3 = 17 Remaining")
	end)

	T.it("previews remaining from placed letters even when the word is invalid", function()
		local sb = require("word_game.ui.score_banner")
		local placement_word = require("word_game.model.jumble.placement_word")
		local rules = require("word_game.model.jumble_play.jumble_rules")
		WORD_GAME_UI.ScoreBanner = sb
		WORD_GAME.Jumble = jumble
		mock_env.patch_game({
			word_round = {
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
			},
		})
		sb.reset_jumble_score()
		local game = mock_env.game_state()
		placement_word.refresh_from_jumble_slots(game.word_round.jumble.slots)
		sb.update(0.2)
		T.assert_false(mock_env.game_state().placement_word_valid, "Invalid words stay invalid until play")
		T.assert_equal(sb.points_got, 3, "Invalid CXT should still preview 3 points")
		T.assert_equal(rules.remaining_to_target(mock_env.game_state().word_round.jumble, 25), 22)
	end)
end)
