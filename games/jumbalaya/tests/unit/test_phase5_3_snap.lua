--[[ tests/unit/test_phase5_3_snap.lua - Phase 5.3 Snap and placement store dispatch test ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local snap = require("word_game.board.placement.snap")
local Store = require("jumbalaya_core.store")
local word_game = require("word_game")

T.describe("Phase 5.3 Snap & Placement Store Integration", function()
	mock_env.reset_game()

	local function make_card(id, letter, pile_id)
		return {
			id = id or 100,
			letter = letter or "A",
			pile_id = pile_id or "hand",
			T = { x = 2.5, y = 2, w = 1, h = 1.4 },
			VT = { x = 2.5, y = 2, w = 1, h = 1.4 },
			area = nil,
			REMOVED = nil,
			states = {
				drag = { can = true, is = false },
				collide = { can = true, is = false },
			},
			selected = false,
			set_card_area = function(self, a) self.area = a end,
		}
	end

	T.it("place_in_row dispatches MOVE_CARD to store and updates card pile_id", function()
		local store = Store.new()
		word_game._bind_store(store)

		local card = make_card(100, "A", "hand")
		store:dispatch({ type = "ADD_CARD_TO_PILE", pile_id = "hand", card = card, slot_index = 1 })

		local session = {
			area = {
				cards = {},
				T = { x = 2, y = 2, w = 10, h = 1.4 },
				hard_set_cards = function() end,
			},
			ctx = {
				card_w = function() return 1 end,
				card_h = function() return 1.4 end,
			},
			card_shimmer_t = {},
		}

		WORD_GAME.Jumble = {
			is_active = function() return true end,
			state = function()
				return {
					slots = {},
					puzzle = { span = { "A" }, min = 1, max = 5, kind = "span" },
				}
			end,
			remove_card_from_blanks = function() end,
			blank_slot_index_for_x = function() return 1, nil end,
			first_empty_blank = function() return 1 end,
			assign_card_to_blank = function() end,
		}

		local placed = snap.place_in_row(session, card)
		T.assert_true(placed, "place_in_row should succeed")
		T.assert_equal(card.pile_id, "pattern")
		T.assert_equal(card.slot_index, 1)

		local state = store:get()
		T.assert_equal(#state.piles.hand, 0)
		T.assert_equal(#state.piles.pattern, 1)
		T.assert_equal(state.piles.pattern[1].id, 100)

		WORD_GAME.Jumble = nil
	end)

	T.it("return_to_hand dispatches MOVE_CARD back to hand pile in store", function()
		local store = Store.new()
		word_game._bind_store(store)

		local card = make_card(101, "B", "pattern")
		store:dispatch({ type = "ADD_CARD_TO_PILE", pile_id = "pattern", card = card, slot_index = 1 })

		local session = {
			area = {
				cards = { card },
				T = { x = 2, y = 2, w = 10, h = 1.4 },
				hard_set_cards = function() end,
			},
			ctx = {
				card_w = function() return 1 end,
				card_h = function() return 1.4 end,
			},
		}

		card.area = session.area

		G.dealt_letters = {
			cards = {},
			emplace = function(self, c) table.insert(self.cards, c) end,
			relayout = function() end,
			snap_VT = function() end,
			hard_set_cards = function() end,
			T = { x = 1, y = 8, w = 10, h = 1.4 },
		}

		WORD_GAME.Jumble = {
			is_active = function() return true end,
			remove_card_from_blanks = function() end,
		}

		local returned = snap.return_to_hand(session, card)
		T.assert_true(returned, "return_to_hand should succeed")
		T.assert_equal(card.pile_id, "hand")

		local state = store:get()
		T.assert_equal(#state.piles.pattern, 0)
		T.assert_equal(#state.piles.hand, 1)
		T.assert_equal(state.piles.hand[1].id, 101)

		G.dealt_letters = nil
		WORD_GAME.Jumble = nil
	end)
end)
