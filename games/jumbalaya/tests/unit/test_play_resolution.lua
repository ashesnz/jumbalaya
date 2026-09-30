--[[ tests/unit/test_play_resolution.lua - Play resolution and placement entry ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("play resolution", function()
	mock_env.reset_game()

	local function base_wr()
		return {
			target = 100,
			mode = "jumble",
			jumble = {
				puzzle_index = 1,
				solved = false,
				total_score = 0,
				puzzle_points = 0,
				puzzle_multi = 1.0,
				puzzle_words = {},
				slots = {
					{ kind = "fixed", letter = "C" },
					{ kind = "span", cards = {}, min = 1, max = 5 },
					{ kind = "fixed", letter = "T" },
				},
				puzzle = { span = { "C", "T" }, min = 3, max = 7, kind = "span" },
			},
		}
	end

	T.it("resolve surfaces invalid plays without advancing the puzzle", function()
		local play = require("word_game.model.jumble_play")
		local resolution = require("word_game.ui.play_effects.resolution")
		local effects = require("word_game.ui.play_effects")
		local shown
		local orig = effects.show_validation_error
		effects.show_validation_error = function(err)
			shown = err
		end

		mock_env.publish_game({ word_round = base_wr(), word_score_animating = false })
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.Jumble = require("word_game.model.jumble")

		local result = resolution.resolve(play)
		T.assert_not_nil(result)
		T.assert_equal(result.kind, "invalid")
		T.assert_equal(result.err, "Word must be played!")
		T.assert_equal(base_wr().jumble.puzzle_index, 1)
		T.assert_equal(shown, "Word must be played!")

		effects.show_validation_error = orig
	end)

	T.it("resolve banks a solved puzzle and advances when target is not yet met", function()
		local play = require("word_game.model.jumble_play")
		local resolution = require("word_game.ui.play_effects.resolution")
		local effects = require("word_game.ui.play_effects")
		local feedback
		local orig_feedback = effects.show_puzzle_bank_feedback
		effects.show_puzzle_bank_feedback = function(total)
			feedback = total
		end

		local wr = base_wr()
		wr.jumble.solved = true
		wr.jumble.puzzle_points = 4
		wr.jumble.puzzle_multi = 1.2
		mock_env.publish_game({ word_round = wr, word_score_animating = false, run_mode = "time_run" })
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.Jumble = require("word_game.model.jumble")
		WORD_GAME.Play = play

		local result = resolution.resolve(play, { instant = true })
		T.assert_equal(result.kind, "bank_puzzle")
		T.assert_not_equal(mock_env.game_state().word_round.jumble.puzzle_index, 1)
		T.assert_equal(feedback, 4)

		effects.show_puzzle_bank_feedback = orig_feedback
	end)

	T.it("banks a scored puzzle when the live row is empty but slots still list old cards", function()
		local play = require("word_game.model.jumble_play")
		local resolution = require("word_game.ui.play_effects.resolution")
		local effects = require("word_game.ui.play_effects")
		local shell = require("jumbalaya-engine.shell")
		local feedback
		local orig_feedback = effects.show_puzzle_bank_feedback
		effects.show_puzzle_bank_feedback = function(total)
			feedback = total
		end

		local wr = base_wr()
		wr.jumble.solved = false
		wr.jumble.puzzle_words = { "CAT" }
		wr.jumble.puzzle_points = 3
		wr.jumble.puzzle_multi = 1.0
		wr.jumble.slots[2].cards = { { ability = { letter = "A" }, REMOVED = true } }

		local game = shell.game()
		game.pattern_row = game.pattern_row or {}
		game.pattern_row.area = { T = { x = 0, y = 0, w = 8, h = 1 }, cards = {} }

		mock_env.publish_game({ word_round = wr, word_score_animating = false, run_mode = "time_run" })
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.Jumble = require("word_game.model.jumble")
		WORD_GAME.Play = play

		local result = resolution.resolve(play, { instant = true })
		T.assert_equal(result.kind, "bank_puzzle")
		T.assert_not_equal(mock_env.game_state().word_round.jumble.puzzle_index, 1)
		T.assert_equal(feedback, 3)

		effects.show_puzzle_bank_feedback = orig_feedback
	end)

	T.it("placement try_play respects InputLock and delegates to resolution", function()
		local placement = require("word_game.ui.table.controls.placement")
		local play = require("word_game.model.jumble_play")
		local resolved = false
		local resolution = require("word_game.ui.play_effects.resolution")
		local orig_resolve = resolution.resolve
		resolution.resolve = function(mod)
			resolved = mod == play
			return { kind = "invalid", err = "blocked" }
		end

		mock_env.publish_game({
			word_round = base_wr(),
			word_score_animating = true,
		})
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.Play = play
		WORD_GAME_UI = WORD_GAME_UI or {}
		WORD_GAME_UI.PlayHoldRedraw = { consume_click = function() return false end }

		placement.try_play()
		T.assert_false(resolved, "busy table should not call resolve")

		require("word_game.model.game_access").patch({ word_score_animating = false })
		placement.try_play()
		T.assert_true(resolved, "idle table should call resolve")

		resolution.resolve = orig_resolve
	end)
end)
