--[[ tests/unit/test_word_feedback_draw.lua - Board attention text draws over the table ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local shell = require("jumbalaya-engine.shell")

T.describe("word feedback draw", function()
	T.it("draws spawn_attention overlays after the table board", function()
		mock_env.reset_game()
		local game = shell.game()
		game.LIVE = game.LIVE or {}
		game.LIVE.UIBOX = {}
		game.HAND_CLEAR_OVERLAY = nil

		local drawn = 0
		game.LIVE.UIBOX[1] = {
			REMOVED = false,
			spawn_attention = true,
			translate_container = function() end,
			draw = function()
				drawn = drawn + 1
			end,
		}
		_G.WORD_GAME_UI = _G.WORD_GAME_UI or {}

		local passes = require("word_game.ui.table.board_draw_passes")
		passes.draw_attention_passes()
		T.assert_equal(drawn, 1, "attention overlays must draw in the post-board pass")
	end)

	T.it("flags the live panel so the early UI pass can skip it", function()
		mock_env.reset_game()
		local host = {
			_inner = {},
			root_node = {
				children = {
					{ config = { object = { pulse = function() end } } },
				},
			},
		}
		local UIViewHost = require("jumbalaya-engine.panels.view_host")
		local orig_create = UIViewHost.create
		UIViewHost.create = function()
			return host
		end
		local Scheduler = require("jumbalaya-engine.effects.timeline_scheduler")
		local orig_add = Scheduler.add
		Scheduler.add = function(opts)
			if (opts.delay or 0) == 0 and opts.func then
				opts.func()
			end
		end

		require("word_game.ui.feedback.word_feedback_spawn").spawn_attention({
			text = "Word must be played!",
			colour = { 1, 0, 0, 1 },
			hold = 1.6,
		})

		Scheduler.add = orig_add
		UIViewHost.create = orig_create
		T.assert_true(host.spawn_attention)
		T.assert_true(host._inner.spawn_attention)
	end)
end)
