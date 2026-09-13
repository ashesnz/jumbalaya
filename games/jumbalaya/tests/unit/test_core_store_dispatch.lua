--[[ tests/unit/test_core_store_dispatch.lua - store dispatch reducers without G ]]

local core_env = require("tests.helpers.core_env")
core_env.setup_package_path()

local T = require("tests.framework")
local Store = require("jumbalaya_core.store")

T.describe("jumbalaya_core store dispatch", function()
	T.it("initializes a run via ROUND_INIT_RUN", function()
		local store = Store.new()
		store:dispatch({ type = "ROUND_INIT_RUN" })
		local state = store:get()
		T.assert_not_nil(state.word_round)
		T.assert_equal(state.word_round.set, 1)
		T.assert_equal(state.voucher_discards_used, 0)
	end)

	T.it("advances hand coordinates via ROUND_START_HAND", function()
		local store = Store.new()
		store:dispatch({ type = "ROUND_INIT_RUN" })
		store:dispatch({ type = "ROUND_START_HAND", set = 1, hand_index = 2 })
		T.assert_equal(store:get().word_round.hand_index, 2)
	end)

	T.it("records played words via ROUND_RECORD_WORD", function()
		local store = Store.new({ word_round = { played_words = {} } })
		store:dispatch({ type = "ROUND_RECORD_WORD", word = "cat" })
		T.assert_true(store:get().word_round.played_words.CAT)
	end)

	T.it("initializes run_state via RUN_STATE_INIT", function()
		local store = Store.new()
		store:dispatch({ type = "RUN_STATE_INIT" })
		T.assert_not_nil(store:get().run_state)
		T.assert_equal(store:get().run_state.tokens, 0)
	end)

	T.it("marks trade used via RUN_STATE_MARK_TRADE_USED", function()
		local store = Store.new()
		store:dispatch({ type = "RUN_STATE_INIT" })
		store:dispatch({ type = "RUN_STATE_MARK_TRADE_USED" })
		T.assert_true(store:get().run_state.trade_used_this_hand)
	end)

	T.it("patches top-level fields via GAME_PATCH", function()
		local store = Store.new()
		store:dispatch({ type = "GAME_PATCH", patch = { deck_left_count = 12 } })
		T.assert_equal(store:get().deck_left_count, 12)
	end)

	T.it("sets placement preview via SET_PLACEMENT_PREVIEW", function()
		local store = Store.new()
		store:dispatch({ type = "SET_PLACEMENT_PREVIEW", word = "cat", valid = true })
		T.assert_equal(store:get().placement_word, "cat")
		T.assert_true(store:get().placement_word_valid)
	end)

	T.it("tracks busy flags via SET_BUSY_FLAG and CLEAR_BUSY_FLAGS", function()
		local store = Store.new()
		store:dispatch({ type = "SET_BUSY_FLAG", name = "trade_ui_busy", on = true })
		T.assert_true(store:get().trade_ui_busy)
		store:dispatch({ type = "CLEAR_BUSY_FLAGS", names = { "trade_ui_busy" } })
		T.assert_nil(store:get().trade_ui_busy)
	end)

	T.it("ends match via RUN_MATCH_END", function()
		local store = Store.new()
		store:dispatch({ type = "RUN_STATE_INIT" })
		store:dispatch({ type = "RUN_MATCH_END", won = true })
		T.assert_true(store:get().run_state.match_over)
		T.assert_true(store:get().run_state.match_won)
	end)

	T.it("clears jumble hand via END_JUMBLE_HAND", function()
		local store = Store.new({
			word_score_animating = true,
			word_round = {
				set = 1,
				hand_index = 1,
				mode = "jumble",
				jumble = { total_score = 42 },
			},
		})
		store:dispatch({ type = "END_JUMBLE_HAND" })
		local state = store:get()
		T.assert_nil(state.word_round.mode)
		T.assert_nil(state.word_round.jumble)
		T.assert_false(state.word_score_animating)
	end)

	T.it("syncs pile snapshots via SYNC_PILES", function()
		local store = Store.new()
		store:dispatch({
			type = "SYNC_PILES",
			piles = {
				hand = { { id = 1, pile_id = "hand", ability = { letter = "A" } } },
				draw = {},
				pattern = {},
				bonus = {},
				discard = {},
			},
		})
		T.assert_equal(store:get().piles.hand[1].id, 1)
	end)

	T.it("returns a new top-level state table on dispatch", function()
		local store = Store.new({ round = 1 })
		local before = store:get()
		store:dispatch({ type = "GAME_PATCH", patch = { round = 2 } })
		local after = store:get()
		T.assert_not_equal(before, after)
		T.assert_equal(after.round, 2)
	end)

	T.it("syncs voucher discard counts via SET_VOUCHER_DISCARDS_USED", function()
		local store = Store.new()
		store:dispatch({ type = "SET_VOUCHER_DISCARDS_USED", count = 2 })
		T.assert_equal(store:get().voucher_discards_used, 2)
		T.assert_equal(store:get().discard_bin_count, 2)
	end)
end)
