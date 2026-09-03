--[[ tests/unit/test_letter_modifiers.lua - Letter modifier definitions and effects ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local LetterPalette = require("word_game.config.letter_card_palette")

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

	T.it("updates the deck card face color when a modifier is applied", function()
		G.P_CARDS = G.P_CARDS or {}
		G.P_CARDS.modified_E = { letter = "E", color = LetterPalette.MODIFIED_FACE_COLOR, pos = { x = 0, y = 0 } }
		local applied_front = nil
		local card = {
			ability = { letter = "E", letter_color = "red" },
			config = { center = {} },
			apply_face = function(self, front)
				applied_front = front
				self.config.card = front
			end,
		}
		T.assert_true(deck.apply_to_card(card))
		T.assert_equal(card.ability.letter_color, LetterPalette.MODIFIED_FACE_COLOR)
		T.assert_equal(deck.color_from_card(card), LetterPalette.MODIFIED_FACE_COLOR)
		T.assert_not_nil(applied_front)
		T.assert_equal(applied_front.color, LetterPalette.MODIFIED_FACE_COLOR)
	end)

	T.it("prefers the modified flag over a stale red letter_color", function()
		local card = { ability = { letter = "E", letter_color = "red", modified = true } }
		T.assert_equal(deck.color_from_card(card), LetterPalette.MODIFIED_FACE_COLOR)
	end)

	T.it("restore_letter_face keeps modified cards on the modified face", function()
		G.P_CARDS = G.P_CARDS or {}
		G.P_CARDS.modified_K = { letter = "K", color = LetterPalette.MODIFIED_FACE_COLOR, pos = { x = 4, y = 0 } }
		local applied_front = nil
		local card = {
			ability = { letter = "K", letter_color = "red", modified = true },
			config = { center = {} },
			set_sprites = function(self, _center, front)
				applied_front = front
			end,
		}
		deck.restore_letter_face(card)
		T.assert_not_nil(applied_front)
		T.assert_equal(applied_front.color, LetterPalette.MODIFIED_FACE_COLOR)
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
		local card = { ability = { letter = "K", letter_color = "red" }, REMOVED = false }
		G.playing_cards[1] = card
		G.deck = { cards = { card }, config = {} }
		state.get().tokens = 100

		local item = { letter = "K", card = card, mode = "market" }
		local ok = trade.apply(item, { action = "modifier" })
		T.assert_true(ok, "Modifier apply should succeed")
		T.assert_true(deck.is_modified(card), "Card should receive permanent modifier")
		T.assert_equal(card.ability.letter_color, LetterPalette.MODIFIED_FACE_COLOR)
		T.assert_equal(deck.color_from_card(card), LetterPalette.MODIFIED_FACE_COLOR)
		T.assert_equal(state.tokens(), 70, "Modifier should cost 30 tokens")
	end)

	T.it("keeps the modified card in the deck inventory after purchase", function()
		G.playing_cards = {}
		local card = { ability = { letter = "T", letter_color = "black" }, REMOVED = false }
		G.playing_cards[1] = card
		G.deck = { cards = { card }, config = {} }
		state.get().tokens = 100

		local item = { letter = "T", card = card, mode = "market" }
		local ok = trade.apply(item, { action = "modifier" })
		T.assert_true(ok)
		T.assert_equal(G.playing_cards[1], card, "Modified card should stay in deck inventory")
		T.assert_false(card.REMOVED, "Modified card should not be removed from the deck")
		T.assert_true(deck.is_modified(G.playing_cards[1]))
		T.assert_equal(deck.color_from_card(G.playing_cards[1]), LetterPalette.MODIFIED_FACE_COLOR)
	end)
end)
