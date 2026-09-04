--[[ tests/unit/test_perk_effects.lua - Perk gameplay hooks ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local perk_effects = require("word_game.model.perks.effects")
local state = require("word_game.model.state")
local jumble = require("word_game.model.jumble")

T.describe("perk effects", function()
	mock_env.reset_game()

	local function reset_perks()
		G.GAME = G.GAME or {}
		G.GAME.run_state = state.new()
	end

	T.it("wide_hand increases hand size by one", function()
		reset_perks()
		T.assert_equal(perk_effects.hand_size_bonus(), 0)
		state.add_perk("wide_hand")
		T.assert_equal(perk_effects.hand_size_bonus(), 1)
		local hand_size = require("word_game.config.hand_size")
		local dimensions = require("word_game.config.dimensions")
		T.assert_equal(hand_size.get(), dimensions.layout.TABLE_HAND_SIZE + 1)
	end)

	T.it("combo_starter and combo_master change puzzle multiplier ramp", function()
		reset_perks()
		state.add_perk("combo_starter")
		T.assert_almost_equal(perk_effects.puzzle_multi_for_word_count(1), 1.2, 0.01)
		T.assert_almost_equal(perk_effects.puzzle_multi_for_word_count(2), 1.4, 0.01)
		state.add_perk("combo_master")
		T.assert_almost_equal(perk_effects.puzzle_multi_for_word_count(3), 1.8, 0.01)
	end)

	T.it("combo_keeper carries multiplier into the next puzzle", function()
		reset_perks()
		G.GAME = G.GAME or {}
		G.GAME.word_round = { set = 1, hand_index = 1, jumble = {} }
		local j = G.GAME.word_round.jumble
		state.add_perk("combo_keeper")
		j.puzzle_multi = 1.6
		perk_effects.on_puzzle_bank(j)
		perk_effects.on_puzzle_start(j, G.GAME.word_round)
		T.assert_almost_equal(j.puzzle_multi, 1.3, 0.01)
	end)

	T.it("greedy boosts banked puzzle totals with three words", function()
		reset_perks()
		state.add_perk("greedy")
		local j = { puzzle_words = { "ONE", "TWO", "THREE" } }
		T.assert_almost_equal(perk_effects.bank_total_multiplier(j), 1.2, 0.01)
	end)

	T.it("long_word adds bonus points through record_puzzle_word", function()
		reset_perks()
		state.add_perk("long_word")
		G.GAME.word_round = {
			mode = "jumble",
			jumble = {
				puzzle_index = 1,
				solved = false,
				puzzle_points = 0,
				puzzle_multi = 1.0,
				puzzle_words = {},
				slots = {},
				puzzle = { span = { "C", "T" }, min = 3, max = 7, kind = "span" },
				puzzle_started_at = 0,
			},
		}
		G.TIMERS = G.TIMERS or { REAL = 0 }
		local _, new_pts = jumble.record_puzzle_word("LENGTH")
		T.assert_equal(new_pts, 21, "6-letter word should score 6 + 15 bonus")
	end)
end)
