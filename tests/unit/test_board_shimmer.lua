--[[ tests/unit/test_board_shimmer.lua
     Gold lock-in shimmer around cards placed into the placement row.
]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("placement row lock-in shimmer", function()
	mock_env.reset_game()
	G.TILESCALE = G.TILESCALE or 4
	G.TILESIZE = G.TILESIZE or 20

	local config = require("word_game.board.config")
	local shimmer = require("word_game.board.shimmer")
	local snap = require("word_game.board.snap")

	local function make_session()
		return {
			area = {
				cards = {},
				T = { x = 2, y = 2, w = 10, h = 1.4 },
				hard_set_cards = function() end,
			},
			card_shimmer_t = {},
			ctx = {
				card_w = function() return 1 end,
				card_h = function() return 1.4 end,
			},
		}
	end

	local function make_card()
		return {
			T = { x = 6.5, y = 2, w = 1, h = 1.4 },
			VT = { x = 6.5, y = 2, w = 1, h = 1.4 },
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

	local function mock_jumble(slot_i)
		WORD_GAME.Jumble = {
			is_active = function() return true end,
			state = function()
				return {
					slots = {},
					puzzle = { span = { "C", "T" }, min = 3, max = 7, kind = "span" },
				}
			end,
			remove_card_from_blanks = function() end,
			blank_slot_index_for_x = function() return slot_i, nil end,
			first_empty_blank = function() return slot_i end,
			assign_card_to_blank = function() end,
			build_word = function() return "" end,
		}
	end

	T.it("starts the shimmer when a card is placed into the row", function()
		mock_jumble(1)
		local session = make_session()
		local card = make_card()

		local placed = snap.place_in_row(session, card)

		T.assert_true(placed, "place_in_row should report success")
		T.assert_equal(session.card_shimmer_t[card], config.LOCK_SHIMMER_DURATION,
			"placing a card must arm its lock-in shimmer")
		T.assert_equal(card.area, session.area, "placed card should belong to the placement area")
	end)

	T.it("draws the gold outline while active and stops once expired", function()
		mock_jumble(1)
		local session = make_session()
		local card = make_card()
		snap.place_in_row(session, card)
		card.area = session.area

		local rect_calls = 0
		local prev_rect = love.graphics.rectangle
		love.graphics.rectangle = function() rect_calls = rect_calls + 1 end

		shimmer.draw(session)
		love.graphics.rectangle = prev_rect
		T.assert_true(rect_calls > 0, "active shimmer must draw outline rectangles")

		shimmer.update(session, config.LOCK_SHIMMER_DURATION / 2)
		T.assert_true((session.card_shimmer_t[card] or 0) > 0,
			"halfway through the duration the timer should still be positive")

		shimmer.update(session, config.LOCK_SHIMMER_DURATION)
		T.assert_equal(session.card_shimmer_t[card], 0, "timer should reach zero after the duration")

		rect_calls = 0
		local prev_rect2 = love.graphics.rectangle
		love.graphics.rectangle = function() rect_calls = rect_calls + 1 end
		shimmer.draw(session)
		love.graphics.rectangle = prev_rect2
		T.assert_equal(rect_calls, 0, "expired shimmer must not draw")
	end)

	T.it("clears shimmer state when a card is removed from the row", function()
		local session = make_session()
		local card = make_card()
		shimmer.start_card(session, card)
		T.assert_not_nil(session.card_shimmer_t[card])

		snap.clear_card(session, card)

		T.assert_nil(session.card_shimmer_t[card], "clear_card must drop the shimmer entry")
	end)

	T.it("re-drop of a row card back onto the row re-arms the shimmer via try_snap", function()
		mock_jumble(1)
		local session = make_session()
		local card = make_card()
		card.area = session.area

		-- Make the card count as an existing jumble slot occupant.
		WORD_GAME.Jumble.state = function()
			return {
				slots = { { kind = "blank", index = 1, card = card } },
				puzzle = { span = { "C", "T" }, min = 3, max = 7, kind = "span" },
			}
		end

		-- Drop lands inside the placement area (centre within area bounds),
		-- and with no G.hand there is no return zone to divert it to.
		snap.try_snap(session, card)

		T.assert_equal(session.card_shimmer_t[card], config.LOCK_SHIMMER_DURATION,
			"try_snap must arm the shimmer for any drop landing in the row")
	end)

	T.it("does not arm the shimmer when a drop returns the card to hand", function()
		mock_jumble(1)
		local session = make_session()
		local card = make_card()
		card.area = session.area

		G.hand = {
			cards = {},
			emplace = function(self, c) table.insert(self.cards, c) end,
			relayout = function() end,
			snap_VT = function() end,
			hard_set_cards = function() end,
			T = { x = 1, y = 8, w = 10, h = 1.4 },
		}
		WORD_GAME.Jumble.remove_card_from_blanks = function() end

		-- Drop point inside the hand/return zone below the placement row.
		card.T.y = 8
		card.VT.y = 8

		snap.try_snap(session, card)

		T.assert_nil(session.card_shimmer_t[card],
			"returning a card to the hand must not trigger the lock-in shimmer")
		G.hand = nil
	end)
end)
