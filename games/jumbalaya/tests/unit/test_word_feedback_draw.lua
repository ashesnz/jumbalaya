--[[ tests/unit/test_word_feedback_draw.lua - Board attention text draws over the table ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local shell = require("jumbalaya-engine.shell")

T.describe("word feedback draw", function()
	T.it("queues Word must be played immediately without the timeline", function()
		mock_env.reset_game()
		local word_feedback = require("word_game.ui.feedback.word_feedback")
		word_feedback.clear()
		word_feedback.show_must_play()
		T.assert_equal(word_feedback.active_count(), 1)
	end)

	T.it("paints queued board messages in the post-board attention pass", function()
		mock_env.reset_game()
		local game = shell.game()
		game.ROOM = game.ROOM or { T = { x = 0, y = 0, w = 20, h = 11 } }
		game.ROOM.translate_container = game.ROOM.translate_container or function() end
		game.TILESCALE = game.TILESCALE or 1
		game.TILESIZE = game.TILESIZE or 20
		game.HAND_CLEAR_OVERLAY = nil
		game.LIVE = game.LIVE or {}
		game.LIVE.PANELS = game.LIVE.PANELS or {}
		_G.WORD_GAME_UI = _G.WORD_GAME_UI or {}

		local painted = 0
		local orig_printf = love.graphics.printf
		love.graphics.printf = function(text)
			if text == "Word must be played!" then
				painted = painted + 1
			end
		end

		local word_feedback = require("word_game.ui.feedback.word_feedback")
		word_feedback.clear()
		word_feedback.show_must_play()
		require("word_game.ui.table.board_draw_passes").draw_attention_passes()
		love.graphics.printf = orig_printf

		T.assert_true(painted >= 1, "red board copy must be printed in the attention pass")
	end)
end)
