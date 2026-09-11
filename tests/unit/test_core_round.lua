--[[ tests/unit/test_core_round.lua - jumbalaya_core round progression without G ]]

local core_env = require("tests.helpers.core_env")
core_env.setup_package_path()

local T = require("tests.framework")
local Core = require("jumbalaya_core")
local Round = Core.Round

T.describe("jumbalaya_core round", function()
	T.it("creates word_round with config targets", function()
		local wr = Round.new_word_round(1, 2)
		T.assert_equal(wr.set, 1)
		T.assert_equal(wr.hand_index, 2)
		T.assert_equal(wr.target, 50)
		T.assert_equal(wr.hand_name, "Standard")
	end)

	T.it("tracks played words on word_round", function()
		local wr = Round.new_word_round(1, 1)
		T.assert_false(Round.is_word_played(wr, "CAT"))
		Round.record_word_play(wr, "cat")
		T.assert_true(Round.is_word_played(wr, "CAT"))
	end)

	T.it("advances within a set then to next set", function()
		local wr = Round.new_word_round(1, 1)
		local action, set, hand = Round.advance_hand(wr)
		T.assert_equal(action, "next")
		T.assert_equal(set, 1)
		T.assert_equal(hand, 2)

		wr = Round.new_word_round(1, 9)
		action, set, hand = Round.advance_hand(wr)
		T.assert_equal(action, "next_set")
		T.assert_equal(set, 2)
		T.assert_equal(hand, 1)
	end)

	T.it("detects final hand and run win", function()
		local wr = Round.new_word_round(8, 3)
		T.assert_true(Round.is_final_hand(wr))
		local action = Round.advance_hand(wr)
		T.assert_equal(action, "win")
	end)

	T.it("normalizes saved word_round defaults and config labels", function()
		local wr = { set = 2, hand_index = 1 }
		Round.normalize_saved_word_round(wr)
		T.assert_equal(wr.set, 2)
		T.assert_equal(wr.hand_index, 1)
		T.assert_equal(wr.target, 400)
		T.assert_equal(wr.hand_name, "Standard")

		local sparse = {}
		Round.normalize_saved_word_round(sparse)
		T.assert_equal(sparse.set, 1)
		T.assert_equal(sparse.hand_index, 1)
		T.assert_equal(sparse.target, 25)
		T.assert_equal(type(sparse.played_words), "table")
	end)
end)
