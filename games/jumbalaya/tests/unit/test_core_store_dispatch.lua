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

	T.it("clears played words via ROUND_CLEAR_PLAYED_WORDS", function()
		local store = Store.new({ word_round = { played_words = { CAT = true } } })
		store:dispatch({ type = "ROUND_CLEAR_PLAYED_WORDS" })
		T.assert_equal(next(store:get().word_round.played_words), nil)
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

	T.it("records stats via RUN_STATE_RECORD_WORD_PLAYED", function()
		local store = Store.new()
		store:dispatch({ type = "RUN_STATE_INIT" })
		store:dispatch({ type = "RUN_STATE_RECORD_WORD_PLAYED" })
		T.assert_equal(store:get().run_state.stats.words_played, 1)
	end)

	T.it("records best puzzle via RUN_STATE_RECORD_PUZZLE_SCORE", function()
		local store = Store.new()
		store:dispatch({ type = "RUN_STATE_INIT" })
		store:dispatch({ type = "RUN_STATE_RECORD_PUZZLE_SCORE", pattern = "CAT", score = 12 })
		T.assert_equal(store:get().run_state.stats.best_puzzle_score, 12)
		T.assert_equal(store:get().run_state.stats.best_puzzle, "CAT")
	end)

	T.it("patches top-level fields via GAME_PATCH", function()
		local store = Store.new()
		store:dispatch({ type = "GAME_PATCH", patch = { deck_left_count = 12 } })
		T.assert_equal(store:get().deck_left_count, 12)
	end)

	T.it("records card discards via RECORD_CARD_DISCARDED", function()
		local store = Store.new({ round_scores = { cards_discarded = { amt = 1 } } })
		store:dispatch({ type = "RECORD_CARD_DISCARDED" })
		T.assert_equal(store:get().round_scores.cards_discarded.amt, 2)
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

	T.it("syncs voucher discard counts via SET_VOUCHER_DISCARDS_USED", function()
		local store = Store.new()
		store:dispatch({ type = "SET_VOUCHER_DISCARDS_USED", count = 2 })
		T.assert_equal(store:get().voucher_discards_used, 2)
		T.assert_equal(store:get().discard_bin_count, 2)
	end)

	T.it("applies jumble puzzle via JUMBLE_APPLY_PUZZLE", function()
		local store = Store.new({
			word_round = {
				set = 1,
				hand_index = 1,
				mode = "jumble",
				jumble = { puzzle_index = 1, puzzle_words = { "OLD" }, puzzle_points = 9 },
			},
		})
		store:dispatch({
			type = "JUMBLE_APPLY_PUZZLE",
			puzzle = { kind = "fixed", pattern = "CAT" },
		})
		local j = store:get().word_round.jumble
		T.assert_equal(j.puzzle.pattern, "CAT")
		T.assert_equal(j.puzzle_points, 0)
		T.assert_equal(#j.puzzle_words, 0)
	end)

	T.it("records jumble word via JUMBLE_RECORD_WORD", function()
		local store = Store.new({
			word_round = {
				mode = "jumble",
				jumble = { puzzle_words = {}, puzzle_points = 0, puzzle_multi = 1.0 },
			},
		})
		store:dispatch({
			type = "JUMBLE_RECORD_WORD",
			jumble = {
				puzzle_words = { "CAT" },
				puzzle_points = 3,
				puzzle_multi = 1.2,
				solved = true,
			},
		})
		local j = store:get().word_round.jumble
		T.assert_equal(j.puzzle_words[1], "CAT")
		T.assert_equal(j.puzzle_points, 3)
		T.assert_equal(j.puzzle_multi, 1.2)
		T.assert_true(j.solved)
	end)

	T.it("advances jumble puzzle via JUMBLE_ADVANCE_PUZZLE", function()
		local puzzles = {
			{ kind = "fixed", pattern = "CAT" },
			{ kind = "fixed", pattern = "DOG" },
		}
		local store = Store.new({
			word_round = {
				set = 1,
				hand_index = 1,
				mode = "jumble",
				jumble = { puzzle_index = 1, puzzle = puzzles[1] },
			},
		})
		store:dispatch({ type = "JUMBLE_ADVANCE_PUZZLE", puzzle_list = puzzles })
		T.assert_equal(store:get().word_round.jumble.puzzle.pattern, "DOG")
	end)

	T.it("clears boss staging via JUMBLE_CLEAR_BOSS_STAGING", function()
		local store = Store.new({
			word_round = {
				mode = "jumble",
				jumble = { boss_word_staging = true },
			},
		})
		store:dispatch({ type = "JUMBLE_CLEAR_BOSS_STAGING" })
		T.assert_false(store:get().word_round.jumble.boss_word_staging)
	end)

	T.it("clears boss staging when revealing boss puzzle", function()
		local store = Store.new({
			word_round = {
				set = 1,
				hand_index = 3,
				mode = "jumble",
				jumble = {
					boss_word_staging = true,
					pending_boss = { boss_word = "ABCDEFGHI", pattern = "A_BCDEFGH_I" },
				},
			},
		})
		store:dispatch({ type = "JUMBLE_REVEAL_BOSS_PUZZLE" })
		local j = store:get().word_round.jumble
		T.assert_false(j.boss_word_staging)
		T.assert_true(j.boss_word_active)
	end)

	T.it("sets locked hand layout via JUMBLE_SET_LOCKED_HAND_LAYOUT", function()
		local store = Store.new({
			word_round = {
				mode = "jumble",
				jumble = { locked_hand_layout = { x = 1, y = 2, w = 3, h = 4 } },
			},
		})
		store:dispatch({
			type = "JUMBLE_SET_LOCKED_HAND_LAYOUT",
			layout = { x = 9, y = 8, w = 7, h = 6 },
		})
		local layout = store:get().word_round.jumble.locked_hand_layout
		T.assert_equal(layout.x, 9)
		T.assert_equal(layout.h, 6)
	end)

	T.it("clears boss jumble flags via JUMBLE_CLEAR_BOSS_STATE", function()
		local store = Store.new({
			word_round = {
				mode = "jumble",
				jumble = {
					boss_word_active = true,
					boss_word_staging = true,
					boss_puzzle_hidden = true,
					pending_boss = { boss_word = "CAT" },
					locked_hand_layout = { x = 0, y = 0, w = 1, h = 1 },
					boss_cards = { { id = "c1" } },
				},
			},
		})
		store:dispatch({ type = "JUMBLE_CLEAR_BOSS_STATE" })
		local j = store:get().word_round.jumble
		T.assert_false(j.boss_word_active)
		T.assert_false(j.boss_word_staging)
		T.assert_false(j.boss_puzzle_hidden)
		T.assert_nil(j.pending_boss)
		T.assert_nil(j.locked_hand_layout)
		T.assert_nil(j.boss_cards)
	end)
end)
