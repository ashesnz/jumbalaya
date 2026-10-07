--[[ tests/unit/test_word_feedback_play_board.lua - Play-board centered word score copy ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local shell = require("jumbalaya-engine.shell")

local PLAY_COLOUR = { 0.94, 0.38, 0.34, 1 }

T.describe("word feedback play board", function()
	T.it("play_board_message_rect matches placement row backdrop bounds", function()
		mock_env.reset_game()
		local game = shell.game()
		game.pattern_row = game.pattern_row or {}
		game.pattern_row.area = {
			T = { x = 2, y = 3, w = 10, h = 1.35 },
		}
		local geometry = require("word_game.ui.feedback.word_feedback_geometry")
		local rect = geometry.play_board_message_rect(0)
		T.assert_not_nil(rect)
		T.assert_equal(rect.x, 2)
		T.assert_equal(rect.y, 3)
		T.assert_equal(rect.w, 10)
		T.assert_equal(rect.h, 1.35)
	end)

	T.it("show_on_play_board queues copy on the placement backdrop rect", function()
		mock_env.reset_game()
		local game = shell.game()
		game.pattern_row = {
			apply_screen_position = function() end,
			area = { T = { x = 2, y = 3, w = 10, h = 1.35 } },
		}
		game.dealt_letters = {
			T = { x = 2, y = 8, w = 10, h = 1.4 },
			cards = {},
		}
		local word_feedback = require("word_game.ui.feedback.word_feedback")
		word_feedback.clear()
		word_feedback.show("hand-gap", { 0, 1, 0, 1 })
		local gap_msg = word_feedback.peek_top_message()
		word_feedback.clear()
		word_feedback.show_on_play_board("CAT  +3", PLAY_COLOUR, 1.2, 0, 0)
		local board_msg = word_feedback.peek_top_message()
		T.assert_not_equal(gap_msg.y, board_msg.y)
		T.assert_equal(board_msg.text, "CAT  +3")
		T.assert_equal(board_msg.colour[2], PLAY_COLOUR[2])
		T.assert_equal(board_msg.h, 1.35)
		T.assert_almost_equal(board_msg.y + board_msg.h * 0.5, 3 + 1.35 * 0.5, 0.001)
	end)

	T.it("show_word_success uses placement backdrop messaging", function()
		mock_env.reset_game()
		local game = shell.game()
		game.pattern_row = {
			apply_screen_position = function() end,
			area = { T = { x = 1, y = 2, w = 12, h = 1.35 } },
		}
		local word_feedback = require("word_game.ui.feedback.word_feedback")
		word_feedback.clear()
		local definition = require("word_game.ui.play_effects.definition")
		definition.show_word_success("CAT")
		local msg = word_feedback.peek_top_message()
		T.assert_equal(msg.text, "CAT  +3")
		T.assert_equal(msg.colour[2], PLAY_COLOUR[2])
		T.assert_equal(msg.h, 1.35)
	end)
end)
