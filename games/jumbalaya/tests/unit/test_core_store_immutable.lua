--[[ tests/unit/test_core_store_immutable.lua - Immutable reducer copy-on-write guarantees ]]

local core_env = require("tests.helpers.core_env")
core_env.setup_package_path()

local T = require("tests.framework")
local Store = require("jumbalaya_core.store")

T.describe("jumbalaya_core store immutability", function()
	T.it("returns a new top-level state table on every dispatch", function()
		local store = Store.new({ round = 1 })
		local before = store:get()
		store:dispatch({ type = "GAME_PATCH", patch = { round = 2 } })
		local after = store:get()
		T.assert_not_equal(before, after)
		T.assert_equal(before.round, 1)
		T.assert_equal(after.round, 2)
	end)

	T.it("copies word_round without mutating the prior snapshot", function()
		local store = Store.new({
			word_round = { played_words = {}, hand_index = 1 },
		})
		local before_wr = store:get().word_round
		store:dispatch({ type = "ROUND_RECORD_WORD", word = "cat" })
		local after_wr = store:get().word_round
		T.assert_not_equal(before_wr, after_wr)
		T.assert_nil(before_wr.played_words.CAT)
		T.assert_true(after_wr.played_words.CAT)
	end)

	T.it("copies run_state without mutating the prior snapshot", function()
		local store = Store.new()
		store:dispatch({ type = "RUN_STATE_INIT" })
		local before_rs = store:get().run_state
		store:dispatch({ type = "RUN_STATE_MARK_TRADE_USED" })
		local after_rs = store:get().run_state
		T.assert_not_equal(before_rs, after_rs)
		T.assert_false(before_rs.trade_used_this_hand)
		T.assert_true(after_rs.trade_used_this_hand)
	end)

	T.it("copies piles without mutating the prior snapshot", function()
		local card = { id = "c1", pile_id = "hand" }
		local store = Store.new({
			piles = { hand = {}, draw = {}, pattern = {}, bonus = {}, discard = {} },
		})
		local before_piles = store:get().piles
		store:dispatch({ type = "ADD_CARD_TO_PILE", pile_id = "hand", card = card })
		local after_piles = store:get().piles
		T.assert_not_equal(before_piles, after_piles)
		T.assert_equal(#before_piles.hand, 0)
		T.assert_equal(#after_piles.hand, 1)
		T.assert_equal(after_piles.hand[1].id, "c1")
	end)

	T.it("preserves unrelated top-level fields across GAME_PATCH", function()
		local store = Store.new({
			chips = 1,
			word_round = { set = 1, hand_index = 1 },
		})
		local before_wr = store:get().word_round
		store:dispatch({ type = "GAME_PATCH", patch = { chips = 99 } })
		T.assert_equal(store:get().word_round, before_wr)
		T.assert_equal(store:get().chips, 99)
	end)

	T.it("copies jumble slots without mutating the prior snapshot", function()
		local slots = { { kind = "blank", index = 1, card = nil } }
		local store = Store.new({
			word_round = {
				mode = "jumble",
				jumble = { slots = slots, puzzle_words = {} },
			},
		})
		local before_slots = store:get().word_round.jumble.slots
		store:dispatch({ type = "END_JUMBLE_HAND" })
		T.assert_equal(before_slots[1].kind, "blank")
		T.assert_nil(store:get().word_round.jumble)
	end)

	T.it("copies jumble state without mutating the prior snapshot", function()
		local store = Store.new({
			word_round = {
				mode = "jumble",
				jumble = { puzzle_words = {}, puzzle_points = 0, puzzle_multi = 1.0 },
			},
		})
		local before_j = store:get().word_round.jumble
		store:dispatch({
			type = "JUMBLE_RECORD_WORD",
			jumble = {
				puzzle_words = { "ZOO" },
				puzzle_points = 5,
				puzzle_multi = 1.5,
				solved = true,
			},
		})
		local after_j = store:get().word_round.jumble
		T.assert_not_equal(before_j, after_j)
		T.assert_equal(#before_j.puzzle_words, 0)
		T.assert_equal(after_j.puzzle_words[1], "ZOO")
	end)
end)
