--[[ tests/unit/test_match_stats.lua
     Match-long jumble stats shown on the game-over screen.
]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("Match jumble stats", function()
	mock_env.reset_game()
	local state = require("word_game.model.state")
	local end_match = require("word_game.ui.end_match")

	local function stats()
		local rs = state.get()
		return rs and rs.stats or {}
	end

	T.it("counts each successful word play", function()
		mock_env.reset_game()
		G.GAME.run_state = state.new()
		state.record_word_played()
		state.record_word_played()
		T.assert_equal(stats().words_played, 2)
	end)

	T.it("keeps the highest scoring jumble puzzle as the player's best", function()
		mock_env.reset_game()
		G.GAME.run_state = state.new()
		state.record_puzzle_score("C_T", 20)
		state.record_puzzle_score("AR_", 50)
		state.record_puzzle_score("…S", 40)
		T.assert_equal(stats().best_puzzle, "AR_")
		T.assert_equal(stats().best_puzzle_score, 50)
	end)

	T.it("formats the game-over summary with best jumble and words played, without sweeps", function()
		local lines = end_match.summary_lines({
			best_puzzle = "C_T",
			best_puzzle_score = 50,
			words_played = 7,
			sweeps = 3,
		})
		T.assert_equal(#lines, 2)
		T.assert_equal(lines[1].label, "Your best jumble")
		T.assert_equal(lines[1].value, "C_T  (50)")
		T.assert_equal(lines[2].label, "Words played")
		T.assert_equal(lines[2].value, 7)
		for _, line in ipairs(lines) do
			T.assert_false(tostring(line.label):find("Sweep"), "Sweeps should not appear on the game-over summary")
			T.assert_false(tostring(line.value):find("Sweep"), "Sweeps should not appear on the game-over summary")
		end
	end)

	T.it("shows an em dash when no jumble has been scored", function()
		T.assert_equal(end_match.best_jumble_value({}), "—")
	end)

	T.it("records the banked puzzle score and pattern as the best jumble", function()
		mock_env.reset_game()
		G.GAME.run_state = state.new()
		local flow = require("word_game.model.jumble_play")
		G.GAME.word_round = {
			target = 100,
			mode = "jumble",
			jumble = {
				puzzle_index = 1,
				solved = true,
				total_score = 0,
				puzzle_points = 15,
				puzzle_multi = 1.6,
				puzzle_words = { "CAT", "CENT", "CHAT", "COT" },
				pattern = "C_T",
				slots = {
					{ kind = "fixed", letter = "C" },
					{ kind = "span", cards = {}, min = 1, max = 5 },
					{ kind = "fixed", letter = "T" },
				},
				puzzle = { kind = "rigid", pattern = "C_T" },
			},
		}
		G.GAME.word_score_animating = false

		require("word_game.ui.play_resolution").resolve(flow)

		T.assert_equal(stats().best_puzzle, "C_T")
		T.assert_equal(stats().best_puzzle_score, 24, "Best jumble should be floor(15 * 1.6) = 24")
	end)

	T.it("counts played words and tracks the current puzzle score", function()
		mock_env.reset_game()
		G.GAME.run_state = state.new()
		local jumble = require("word_game.model.jumble")
		local rules = require("word_game.model.jumble_play.jumble_rules")
		G.GAME.word_round = {
			target = 100,
			mode = "jumble",
			played_words = {},
			jumble = {
				puzzle_points = 0,
				puzzle_multi = 1.0,
				puzzle_words = {},
				pattern = "C_T",
				puzzle = { kind = "rigid", pattern = "C_T" },
				solved = false,
				slots = {
					{ kind = "blank", card = { letter = "A" } },
				},
			},
		}
		local facade = {
			validate_current = function()
				return "CAT"
			end,
			record_puzzle_word = function(word, opts)
				return jumble.record_puzzle_word(word, opts)
			end,
		}

		local result = rules.evaluate_play(facade, G.GAME.word_round.jumble)
		T.assert_equal(result.kind, "word_play")
		T.assert_equal(stats().words_played, 1)
		T.assert_equal(stats().best_puzzle, "C_T")
		T.assert_equal(stats().best_puzzle_score, 3, "CAT should score 3 points on the first word")
	end)

	T.it("captures an unbanked puzzle at game over if it is the player's best", function()
		mock_env.reset_game()
		G.GAME.run_state = state.new()
		G.STATES = G.STATES or {}
		G.STATES.GAME_OVER = 4
		G.GAME.word_round = {
			jumble = {
				pattern = "C_T",
				puzzle_points = 25,
				puzzle_multi = 2.0,
			},
		}
		local Match = require("word_game.model.match")
		Match.end_run({ won = false })
		T.assert_equal(stats().best_puzzle, "C_T")
		T.assert_equal(stats().best_puzzle_score, 50)
	end)
end)
