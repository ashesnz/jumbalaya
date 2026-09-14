--[[ tests/unit/test_pile_boundaries.lua - Store piles vs CardPile presentation boundaries ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local audit = require("tests.helpers.pile_boundary_audit")
local piles = require("word_game.model.piles")
local pile_selectors = require("jumbalaya_core.store.selectors.piles")
local Store = require("jumbalaya_core.store")
local shell = require("jumbalaya-engine.shell")
local word_game = require("word_game")

T.describe("pile boundaries", function()
	mock_env.reset_game()

	T.it("model glue does not import CardPile / cardarea", function()
		local violations = audit.model_cardarea_imports()
		T.assert_equal(#violations, 0, table.concat(violations, ", "))
	end)

	T.it("cardarea package does not import gameplay rules modules", function()
		local violations = audit.cardarea_gameplay_imports()
		T.assert_equal(#violations, 0, table.concat(violations, ", "))
	end)

	T.it("SYNC_PILES is dispatched only from piles.lua", function()
		local violations = audit.direct_sync_piles_dispatch()
		T.assert_equal(#violations, 0, table.concat(violations, ", "))
	end)

	T.it("move_card dispatches MOVE_CARD and mirrors pile_id on the live card", function()
		local store = Store.new({
			piles = {
				hand = { { id = 4, ability = { letter = "T" }, pile_id = "hand" } },
				draw = {},
				pattern = {},
				bonus = {},
				discard = {},
			},
		})
		word_game._bind_store(store)
		local card = { letter_card_id = 4, ability = { letter = "T" }, pile_id = "hand" }
		piles.move_card({
			card = card,
			from_pile = "hand",
			to_pile = "pattern",
			slot_index = 2,
		})
		T.assert_equal(card.pile_id, "pattern")
		T.assert_equal(card.slot_index, 2)
		local state = store:get()
		T.assert_equal(#pile_selectors.hand_cards(state), 0)
		local pattern = pile_selectors.pattern_cards(state)
		T.assert_equal(pattern[2].id, 4)
		T.assert_equal(pattern[2].pile_id, "pattern")
	end)

	T.it("sync_hosts_to_store snapshots CardPile hosts into store piles", function()
		local store = Store.new({
			piles = {
				hand = {},
				draw = {},
				pattern = {},
				bonus = {},
				discard = {},
			},
		})
		word_game._bind_store(store)
		local game = shell.game() or {}
		shell.bind_game(game)
		game.dealt_letters = {
			cards = {
				{ id = 7, letter_card_id = 7, ability = { letter = "E" } },
			},
		}
		game.draw_pile = { cards = {} }
		game.recycle_stash = { cards = {} }

		piles.sync_hosts_to_store(store, { "hand" })
		local state = store:get()
		T.assert_equal(#pile_selectors.hand_cards(state), 1)
		T.assert_equal(state.piles.hand[1].id, 7)
		T.assert_equal(state.piles.hand[1].ability.letter, "E")
	end)

	T.it("commit_hosts syncs store then clears resting host cards", function()
		local store = Store.new({
			piles = {
				hand = {},
				draw = {},
				pattern = {},
				bonus = {},
				discard = {},
			},
		})
		word_game._bind_store(store)
		local game = shell.game() or {}
		shell.bind_game(game)
		local resting = { id = 3, letter_card_id = 3, ability = { letter = "A" } }
		game.dealt_letters = { cards = { resting } }
		game.draw_pile = { cards = {} }
		game.recycle_stash = { cards = {} }

		piles.commit_hosts(store, { "hand" })
		local state = store:get()
		T.assert_equal(#pile_selectors.hand_cards(state), 1)
		T.assert_equal(#game.dealt_letters.cards, 0)
	end)
end)
