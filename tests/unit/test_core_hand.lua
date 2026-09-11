--[[ tests/unit/test_core_hand.lua - jumbalaya_core jumble hand lifecycle without G ]]

local core_env = require("tests.helpers.core_env")
core_env.setup_package_path()

local T = require("tests.framework")
local Core = require("jumbalaya_core")
local Hand = Core.Jumble.Hand
local PuzzleSpec = Core.Jumble.PuzzleSpec

T.describe("jumbalaya_core jumble hand", function()
	local function sample_puzzles()
		return {
			PuzzleSpec.resolve_puzzle({ span = { "C", "T" }, min = 3, max = 7 }),
			PuzzleSpec.resolve_puzzle({ prefix = "C", min = 3, max = 7 }),
		}
	end

	T.it("starts a hand with jumble state and first puzzle", function()
		local wr = { set = 1, hand_index = 1, target = 25 }
		Hand.start_hand(wr, { puzzle_list = sample_puzzles() })
		T.assert_equal(wr.mode, "jumble")
		T.assert_not_nil(wr.jumble)
		T.assert_equal(wr.jumble.puzzle_index, 1)
		T.assert_not_nil(wr.jumble.slots)
		T.assert_equal(#wr.jumble.slots, 3)
	end)

	T.it("records puzzle words with combo multiplier ramp", function()
		local wr = { set = 1, hand_index = 1, target = 25 }
		Hand.start_hand(wr, { puzzle_list = sample_puzzles() })
		local j = wr.jumble
		local opts = { wr = wr, perks = {} }

		local _, new1, _, m1 = Hand.record_puzzle_word(j, "CAT", opts)
		T.assert_equal(new1, 3)
		T.assert_almost_equal(m1, 1.0, 0.01)

		local _, new2, _, m2 = Hand.record_puzzle_word(j, "CENT", opts)
		T.assert_equal(new2, 7)
		T.assert_almost_equal(m2, 1.2, 0.01)
	end)

	T.it("advances to the next puzzle in the list", function()
		local puzzles = sample_puzzles()
		local wr = { set = 1, hand_index = 1, target = 25, jumble = { puzzle_index = 1, puzzle_points = 0, puzzle_words = {} } }
		Hand.start_hand(wr, { puzzle_list = puzzles })
		Hand.advance_puzzle(wr, puzzles)
		T.assert_equal(wr.jumble.puzzle_index, 2)
	end)

	T.it("prepares and reveals boss word state", function()
		local boss = {
			kind = "rigid",
			pattern = "_O_",
			boss_word = "DOG",
			display = "_O_",
		}
		local wr = {
			set = 1,
			hand_index = 3,
			jumble = { puzzle_index = 1, slots = { { kind = "blank" } } },
		}
		T.assert_true(Hand.prepare_boss_word(wr, boss))
		T.assert_true(wr.jumble.boss_puzzle_hidden)
		T.assert_nil(wr.jumble.slots)
		T.assert_true(Hand.reveal_boss_puzzle(wr))
		T.assert_true(wr.jumble.boss_word_active)
		T.assert_not_nil(wr.jumble.slots)
	end)
end)
