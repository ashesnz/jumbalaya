--[[ tests/unit/test_letter_modifiers.lua - Letter modifier definitions and effects ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("Letter modifiers (word_game.model.cards.deck.letter_modifiers)", function()
	mock_env.reset_game()
	local deck = require("word_game.model.cards.deck")
	local effects = require("word_game.model.play.letter_modifier_effects")

	T.it("defines a unique marketplace description for every letter A–Z", function()
		for i = 1, 26 do
			local letter = string.char(string.byte("A") + i - 1)
			local text = deck.modifier_description(letter)
			T.assert_true(type(text) == "string" and #text > 10, "Missing description for " .. letter)
		end
	end)

	T.it("applies a permanent modified flag to a deck card", function()
		local card = { ability = { letter = "E" } }
		T.assert_true(deck.apply_to_card(card), "Should apply modifier")
		T.assert_true(deck.is_modified(card), "Card should be marked modified")
		T.assert_false(deck.apply_to_card(card), "Should not apply twice")
	end)

	T.it("gives E +1 bonus point when the modified E card is played", function()
		local card = { ability = { letter = "E", modified = true } }
		local j = { puzzle_words = {}, puzzle_started_at = 0, last_word_played_at = 0 }
		local wr = {}
		G.TIMERS = { REAL = 0 }
		local result = effects.apply_word_effects("PET", { card }, j, wr)
		T.assert_equal(result.bonus_points, 1, "Modified E should add 1 point")
	end)

	T.it("banks +3 bonus points from modified B after puzzle bank", function()
		local j = { modifier_b_pending = true }
		T.assert_equal(effects.bank_bonus_points(j), 3)
		T.assert_equal(effects.bank_bonus_points(j), 0, "B bonus should only apply once")
	end)

	T.it("inserts U after Q for modified Q words missing QU", function()
		local card = { ability = { letter = "Q", modified = true } }
		T.assert_equal(effects.adjust_word_for_q("QUIT", { card }), "QUIT")
		T.assert_equal(effects.adjust_word_for_q("IQ", { card }), "IQU")
	end)
end)

T.describe("Trade modifier application (word_game.model.trade)", function()
	mock_env.reset_game()
	local trade = require("word_game.model.trade")
	local deck = require("word_game.model.cards.deck")
	local state = require("word_game.model.state")

	T.it("applies the letter modifier to an in-deck card for 30 tokens", function()
		G.playing_cards = {}
		local card = { ability = { letter = "K" }, REMOVED = false }
		G.playing_cards[1] = card
		G.deck = { cards = { card }, config = {} }
		state.get().tokens = 100

		local item = { letter = "K", card = card, mode = "market" }
		local ok = trade.apply(item, { action = "modifier" })
		T.assert_true(ok, "Modifier apply should succeed")
		T.assert_true(deck.is_modified(card), "Card should receive permanent modifier")
		T.assert_equal(state.tokens(), 70, "Modifier should cost 30 tokens")
	end)
end)
