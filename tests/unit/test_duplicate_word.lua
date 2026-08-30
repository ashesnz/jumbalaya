--[[ tests/unit/test_duplicate_word.lua
     Tests for duplicate word tracking and validation across stages/hands.
]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("Duplicate Word Tracking (word_game.model.round)", function()
	mock_env.reset_game()
	local round = require("word_game.model.round")

	T.it("initializes without any played words", function()
		round.init_run()
		T.assert_false(round.is_word_played("CAT"), "CAT should not be played initially")
		T.assert_false(round.is_word_played(""), "empty string should not be played")
		T.assert_false(round.is_word_played(nil), "nil should not be played")
	end)

	T.it("records and detects played words case-insensitively", function()
		round.record_word_play("CAT")
		T.assert_true(round.is_word_played("CAT"), "CAT (uppercase) should be marked as played")
		T.assert_true(round.is_word_played("cat"), "cat (lowercase) should be marked as played")
		T.assert_true(round.is_word_played("Cat"), "Cat (mixed case) should be marked as played")
		T.assert_false(round.is_word_played("DOG"), "DOG should not be marked as played")
	end)

	T.it("clears played words when advancing to a new hand or stage", function()
		round.record_word_play("TEST")
		T.assert_true(round.is_word_played("TEST"))

		round.start_hand(1, 2)
		T.assert_false(round.is_word_played("TEST"), "played words should be cleared on new hand")
	end)
end)
