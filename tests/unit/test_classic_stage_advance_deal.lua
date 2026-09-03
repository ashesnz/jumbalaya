--[[ tests/unit/test_classic_stage_advance_deal.lua
     Classic Next → marketplace → stage 1-2 should deal 7 from expanded deck.
]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

local function setup_card_areas()
	mock_env.ensure_engine_globals()
	require("word_game.ui.cardarea")
	require("word_game.model.cards.card")

	G.deck = CardArea(0, 0, 1, 1, { type = "deck", card_limit = 52 })
	G.hand = CardArea(0, 0, 7, 1, { type = "hand", card_limit = 7 })
	G.discard = CardArea(0, 0, 1, 1, { type = "discard", card_limit = 500 })
	G.placement_table = {
		area = CardArea(0, 0, 5, 1, { type = "play" }),
		on_remove_card = function() end,
		relayout = function() end,
		apply_screen_position = function() end,
	}
	G.GAME.deck_alpha = { pos = { x = 0, y = 0 } }
	G.RUN = { active = true }
end

T.describe("Classic stage advance deal", function()
	T.it("deals seven cards on 1-2 after Next, marketplace purchases, and continue", function()
		mock_env.reset_game()
		setup_card_areas()

		local deck = require("word_game.model.cards.deck")
		local play = require("word_game.model.play")
		local trade = require("word_game.model.trade")
		local hand_size = require("word_game.config.hand_size")
		local jumble = require("word_game.model.jumble")

		WORD_GAME.Deck = deck
		WORD_GAME.Jumble = jumble
		jumble.ensure_playable_puzzle = function() return true end
		jumble.refresh_hud = function() end
		WORD_GAME.Play = play
		WORD_GAME.TableDiscard = { reset = function() end }
		WORD_GAME.HandClearFocus = {
			end_focus = function() end,
			is_active = function() return false end,
		}
		WORD_GAME.TradeUI = {
			open_then_dealer = function() end,
		}
		WORD_GAME.TokenReward = {
			try_award = function(callback)
				if callback then callback() end
				return true
			end,
			is_active = function() return false end,
		}
		WORD_GAME.Confetti = { burst = function() end }
		local word_feedback = require("word_game.ui.word_feedback")
		local orig_show = word_feedback.show
		word_feedback.show = function() end

		G.GAME.run_mode = "classic"
		G.GAME.alpha = { tokens = 100, perks = {}, trade_used_this_hand = false }
		G.GAME.word_round = {
			set = 1,
			hand_index = 1,
			target = 25,
			mode = "jumble",
			played_words = {},
			jumble = {
				total_score = 32,
				puzzle_points = 0,
				puzzle_multi = 1.0,
				puzzle_words = {},
				solved = false,
				slots = {},
			},
		}

		deck.populate_starting_deck()
		deck.deal_jumble_hand()
		local starter = #deck.STARTING_LETTERS
		T.assert_equal(#G.hand.cards, hand_size.get(), "Stage 1-1 should open with a full hand")

		-- Simulate played cards sitting in the hidden discard pool mid-hand.
		for _ = 1, 3 do
			local card = G.hand.cards[1]
			if card then
				G.hand:remove_card(card)
				card.played_pool = true
				G.discard:emplace(card)
			end
		end

		local timeline_events = {}
		G.TIMELINE = {
			enqueue = function(_, ev)
				timeline_events[#timeline_events + 1] = ev
			end,
		}
		local function drain_timeline()
			while #timeline_events > 0 do
				local ev = table.remove(timeline_events, 1)
				if ev.func then ev.func() end
			end
		end
		play.on_hand_cleared()
		drain_timeline()

		T.assert_equal(#G.deck.cards, starter,
			"Hand clear should consolidate every live card back into the deck")

		local ok1 = trade.add_letter({ letter = "Z", color = "red" })
		local ok2 = trade.add_letter({ letter = "Q", color = "black" })
		T.assert_true(ok1 and ok2, "Marketplace purchases should succeed")
		local expected = starter + 2
		T.assert_equal(#G.playing_cards, expected, "Purchases should grow the run deck")

		play.continue_after_dealer()
		drain_timeline()

		T.assert_equal(G.GAME.word_round.hand_index, 2, "Should advance to stage 1-2")
		T.assert_equal(G.GAME.word_round.target, 50, "Stage 1-2 target should be 50")
		T.assert_equal(#G.hand.cards, hand_size.get(),
			"Stage 1-2 should deal a full seven-card hand")
		T.assert_equal(#G.deck.cards, expected - hand_size.get(),
			"Remaining deck cards should stay in the draw pile")
		T.assert_equal(deck.cards_left() + deck.held_count(), expected,
			"Every purchased card should remain in the run deck")

		word_feedback.show = orig_show
	end)

	T.it("deals seven after marketplace purchases made before classic Next clears the hand", function()
		mock_env.reset_game()
		setup_card_areas()

		local deck = require("word_game.model.cards.deck")
		local play = require("word_game.model.play")
		local trade = require("word_game.model.trade")
		local hand_size = require("word_game.config.hand_size")
		local jumble = require("word_game.model.jumble")

		WORD_GAME.Deck = deck
		WORD_GAME.Jumble = jumble
		jumble.ensure_playable_puzzle = function() return true end
		jumble.refresh_hud = function() end
		WORD_GAME.Play = play
		WORD_GAME.TableDiscard = { reset = function() end }
		WORD_GAME.HandClearFocus = {
			end_focus = function() end,
			is_active = function() return false end,
		}
		WORD_GAME.TradeUI = { open_then_dealer = function() end }
		WORD_GAME.TokenReward = {
			try_award = function(callback)
				if callback then callback() end
				return true
			end,
			is_active = function() return false end,
		}
		WORD_GAME.Confetti = { burst = function() end }
		local word_feedback = require("word_game.ui.word_feedback")
		local orig_show = word_feedback.show
		word_feedback.show = function() end

		G.GAME.run_mode = "classic"
		G.GAME.alpha = { tokens = 100, perks = {}, trade_used_this_hand = false }
		G.GAME.word_round = {
			set = 1,
			hand_index = 1,
			target = 25,
			mode = "jumble",
			played_words = {},
			jumble = {
				total_score = 32,
				puzzle_points = 0,
				puzzle_multi = 1.0,
				puzzle_words = {},
				solved = false,
				slots = {},
			},
		}

		deck.populate_starting_deck()
		deck.deal_jumble_hand()
		local starter = #deck.STARTING_LETTERS

		trade.add_letter({ letter = "Z", color = "red" })
		trade.add_letter({ letter = "Q", color = "black" })
		local expected = starter + 2

		local timeline_events = {}
		G.TIMELINE = {
			enqueue = function(_, ev)
				timeline_events[#timeline_events + 1] = ev
			end,
		}
		local function drain_timeline()
			while #timeline_events > 0 do
				local ev = table.remove(timeline_events, 1)
				if ev.func then ev.func() end
			end
		end

		play.on_hand_cleared()
		drain_timeline()
		play.continue_after_dealer()
		drain_timeline()

		T.assert_equal(G.GAME.word_round.hand_index, 2)
		T.assert_equal(G.GAME.word_round.target, 50)
		T.assert_equal(#G.hand.cards, hand_size.get())
		T.assert_equal(#G.playing_cards, expected)
		T.assert_equal(deck.cards_left() + deck.held_count(), expected)

		word_feedback.show = orig_show
	end)

	T.it("deals seven even when placement still holds cards across classic stage advance", function()
		mock_env.reset_game()
		setup_card_areas()

		local deck = require("word_game.model.cards.deck")
		local play = require("word_game.model.play")
		local trade = require("word_game.model.trade")
		local hand_size = require("word_game.config.hand_size")
		local jumble = require("word_game.model.jumble")

		WORD_GAME.Deck = deck
		WORD_GAME.Jumble = jumble
		jumble.ensure_playable_puzzle = function() return true end
		jumble.refresh_hud = function() end
		WORD_GAME.Play = play
		WORD_GAME.TableDiscard = { reset = function() end }
		WORD_GAME.HandClearFocus = {
			end_focus = function() end,
			is_active = function() return false end,
		}
		WORD_GAME.TradeUI = { open_then_dealer = function() end }
		WORD_GAME.TokenReward = {
			try_award = function(callback)
				if callback then callback() end
				return true
			end,
			is_active = function() return false end,
		}
		WORD_GAME.Confetti = { burst = function() end }
		local word_feedback = require("word_game.ui.word_feedback")
		local orig_show = word_feedback.show
		word_feedback.show = function() end

		G.GAME.run_mode = "classic"
		G.GAME.alpha = { tokens = 100, perks = {}, trade_used_this_hand = false }
		G.GAME.word_round = {
			set = 1,
			hand_index = 1,
			target = 25,
			mode = "jumble",
			played_words = {},
			jumble = {
				total_score = 32,
				puzzle_points = 0,
				puzzle_multi = 1.0,
				puzzle_words = {},
				solved = false,
				slots = {},
			},
		}

		deck.populate_starting_deck()
		deck.deal_jumble_hand()
		local starter = #deck.STARTING_LETTERS

		while #G.hand.cards > 3 do
			local card = G.hand.cards[1]
			G.hand:remove_card(card)
			G.placement_table.area:emplace(card)
		end
		T.assert_equal(#G.hand.cards, 3)
		T.assert_equal(#G.placement_table.area.cards, 4)

		trade.add_letter({ letter = "Z", color = "red" })
		trade.add_letter({ letter = "Q", color = "black" })
		local expected = starter + 2

		local timeline_events = {}
		G.TIMELINE = {
			enqueue = function(_, ev)
				timeline_events[#timeline_events + 1] = ev
			end,
		}
		local function drain_timeline()
			while #timeline_events > 0 do
				local ev = table.remove(timeline_events, 1)
				if ev.func then ev.func() end
			end
		end

		play.on_hand_cleared()
		drain_timeline()
		play.continue_after_dealer()
		drain_timeline()

		T.assert_equal(G.GAME.word_round.hand_index, 2)
		T.assert_equal(G.GAME.word_round.target, 50)
		T.assert_equal(#G.placement_table.area.cards, 0,
			"Stage opening deal should clear the placement row")
		T.assert_equal(#G.hand.cards, hand_size.get(),
			"Placement leftovers must not reduce the next stage opening deal")
		T.assert_equal(deck.cards_left() + deck.held_count(), expected)

		word_feedback.show = orig_show
	end)
end)
