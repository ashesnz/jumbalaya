--[[ tests/unit/test_table_input.lua - TableInput refresh wiring ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("TableInput", function()
	mock_env.reset_game()
	local TableInput = require("word_game.ui.table.input")

	T.it("refresh_card_input relayouts hand and placement drag ranks", function()
		local hand_calls = 0
		local placement_calls = 0
		G.hand = {
			set_ranks = function()
				hand_calls = hand_calls + 1
			end,
		}
		G.placement_table = {
			area = {
				set_ranks = function()
					placement_calls = placement_calls + 1
				end,
			},
		}

		TableInput.refresh_card_input()
		T.assert_equal(hand_calls, 1)
		T.assert_equal(placement_calls, 1)
	end)

	T.it("refresh_card_input tolerates missing placement table", function()
		local hand_calls = 0
		G.hand = {
			set_ranks = function()
				hand_calls = hand_calls + 1
			end,
		}
		G.placement_table = nil

		TableInput.refresh_card_input()
		T.assert_equal(hand_calls, 1)
	end)
end)
