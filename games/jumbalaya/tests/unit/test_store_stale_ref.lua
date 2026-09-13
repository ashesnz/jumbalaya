--[[ tests/unit/test_store_stale_ref.lua - Stale snapshot guard for immutable store ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local game_access = require("word_game.model.game_access")

T.describe("store stale references", function()
	mock_env.reset_game()

	T.it("invalidates cached word_round after dispatch", function()
		mock_env.patch_game({ word_round = { hand_index = 1, played_words = {} } })
		local wr = game_access.word_round()
		game_access.dispatch({ type = "ROUND_RECORD_WORD", word = "cat" })
		T.assert_nil(wr.played_words.CAT)
		T.assert_true(game_access.word_round().played_words.CAT)
	end)

	T.it("invalidates cached run_state after dispatch", function()
		mock_env.patch_game({ run_state = { tokens = 5, perks = {}, trade_used_this_hand = false } })
		local rs = game_access.get().run_state
		game_access.dispatch({ type = "RUN_STATE_ADD_TOKENS", amount = 3 })
		T.assert_equal(rs.tokens, 5)
		T.assert_equal(game_access.get().run_state.tokens, 8)
	end)

	T.it("invalidates cached jumble slots after END_JUMBLE_HAND", function()
		mock_env.patch_game({
			word_round = {
				mode = "jumble",
				jumble = { slots = { { kind = "blank", index = 1 } } },
			},
		})
		local slots = game_access.word_round().jumble.slots
		game_access.dispatch({ type = "END_JUMBLE_HAND" })
		T.assert_not_nil(slots[1])
		T.assert_nil(game_access.word_round().jumble)
	end)
end)
