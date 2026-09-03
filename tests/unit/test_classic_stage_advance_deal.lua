--[[ tests/unit/test_classic_stage_advance_deal.lua
     Classic Next → marketplace → stage 1-2 should deal 7 from expanded deck.
]]

local T = require("tests.framework")
local fixture = require("tests.helpers.classic_stage_advance")

local ZQ_PURCHASES = {
	{ letter = "Z", color = "red" },
	{ letter = "Q", color = "black" },
}

T.describe("Classic stage advance deal", function()
	T.it("deals seven cards on 1-2 after Next, marketplace purchases, and continue", function()
		local ctx = fixture.begin()
		T.assert_equal(#G.hand.cards, ctx.hand_size.get(),
			"Stage 1-1 should open with a full hand")

		for _ = 1, 3 do
			local card = G.hand.cards[1]
			if card then
				G.hand:remove_card(card)
				card.played_pool = true
				G.discard:emplace(card)
			end
		end

		ctx.clear_hand()
		T.assert_equal(#G.deck.cards, ctx.starter,
			"Hand clear should gather every live card back into the deck")

		fixture.add_letters(ZQ_PURCHASES)
		local expected = ctx.starter + 2
		T.assert_equal(#G.playing_cards, expected, "Purchases should grow the run deck")

		ctx.continue()

		T.assert_equal(G.GAME.word_round.hand_index, 2, "Should advance to stage 1-2")
		T.assert_equal(G.GAME.word_round.target, 50, "Stage 1-2 target should be 50")
		T.assert_equal(#G.hand.cards, ctx.hand_size.get(),
			"Stage 1-2 should deal a full seven-card hand")
		T.assert_equal(#G.deck.cards, expected - ctx.hand_size.get(),
			"Remaining deck cards should stay in the draw pile")
		T.assert_equal(ctx.deck.cards_left() + ctx.deck.held_count(), expected,
			"Every purchased card should remain in the run deck")

		ctx.restore()
	end)

	T.it("deals seven after marketplace purchases made before classic Next clears the hand", function()
		local ctx = fixture.begin()
		fixture.add_letters(ZQ_PURCHASES)
		local expected = ctx.starter + 2

		ctx.advance()

		T.assert_equal(G.GAME.word_round.hand_index, 2)
		T.assert_equal(G.GAME.word_round.target, 50)
		T.assert_equal(#G.hand.cards, ctx.hand_size.get())
		T.assert_equal(#G.playing_cards, expected)
		T.assert_equal(ctx.deck.cards_left() + ctx.deck.held_count(), expected)

		ctx.restore()
	end)

	T.it("deals seven even when placement still holds cards across classic stage advance", function()
		local ctx = fixture.begin()

		while #G.hand.cards > 3 do
			local card = G.hand.cards[1]
			G.hand:remove_card(card)
			G.placement_table.area:emplace(card)
		end
		T.assert_equal(#G.hand.cards, 3)
		T.assert_equal(#G.placement_table.area.cards, 4)

		fixture.add_letters(ZQ_PURCHASES)
		local expected = ctx.starter + 2

		ctx.advance()

		T.assert_equal(G.GAME.word_round.hand_index, 2)
		T.assert_equal(G.GAME.word_round.target, 50)
		T.assert_equal(#G.placement_table.area.cards, 0,
			"Stage opening deal should clear the placement row")
		T.assert_equal(#G.hand.cards, ctx.hand_size.get(),
			"Placement leftovers must not reduce the next stage opening deal")
		T.assert_equal(ctx.deck.cards_left() + ctx.deck.held_count(), expected)

		ctx.restore()
	end)

	T.it("deals on the table board after classic stage advance", function()
		local ctx = fixture.begin({ table_board = true, jumble = { total_score = 32, slots = {} } })
		fixture.add_letters({ { letter = "Z", color = "red" } })
		local expected = ctx.starter + 1

		ctx.advance()

		T.assert_equal(G.GAME.word_round.hand_index, 2)
		T.assert_equal(#G.hand.cards, ctx.hand_size.get(),
			"Table board stage advance should deal a full hand")
		T.assert_true(#G.deck.cards > 0,
			"Remaining cards should stay in the deck pile")
		T.assert_equal(ctx.deck.cards_left() + ctx.deck.held_count(), expected)

		ctx.restore()
	end)

	T.it("restores hand drag after classic stage advance deal on 1-2", function()
		local ctx = fixture.begin({ wire_drag = true })
		fixture.assert_hand_draggable(T, "Stage 1-1")

		ctx.advance({ { letter = "Z", color = "red" } })

		T.assert_equal(G.GAME.word_round.hand_index, 2)
		T.assert_equal(#G.hand.cards, ctx.hand_size.get())
		T.assert_false(G.GAME.word_score_animating,
			"Score animation flag must clear after stage opening deal")
		fixture.assert_hand_draggable(T, "Stage 1-2")

		ctx.restore()
	end)

	T.it("restores hand drag after advancing 1-2 through marketplace to 1-3", function()
		local ctx = fixture.begin({
			wire_drag = true,
			hand_index = 2,
			target = 50,
			total_score = 60,
		})

		ctx.advance({ { letter = "X", color = "red" } })

		T.assert_equal(G.GAME.word_round.hand_index, 3)
		T.assert_equal(#G.hand.cards, ctx.hand_size.get())
		T.assert_false(G.GAME.word_score_animating)
		fixture.assert_hand_draggable(T, "Stage 1-3")

		ctx.restore()
	end)
end)
