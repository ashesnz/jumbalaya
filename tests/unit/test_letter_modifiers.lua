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
			local ui_text = deck.modifier_ui_text(letter)
			T.assert_true(type(ui_text) == "string" and #ui_text > 0, "Missing ui_text for " .. letter)
		end
	end)

	T.it("exposes short ui_text separate from marketplace description", function()
		T.assert_equal(deck.modifier_description("I"), "Gives +1 point.")
		T.assert_equal(deck.modifier_ui_text("I"), "+1 point")
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

T.describe("Vowel letter modifiers (A, E, I, O, U)", function()
	mock_env.reset_game()
	local deck = require("word_game.model.cards.deck")
	local effects = require("word_game.model.play.letter_modifier_effects")

	local function modified_card(letter)
		return { ability = { letter = letter, modified = true } }
	end

	local function fresh_jumble_state()
		return {
			puzzle_words = {},
			puzzle_started_at = 0,
			last_word_played_at = 0,
		}
	end

	T.it("A: description matches +0.2× multiplier when a modified A is played", function()
		T.assert_equal(deck.modifier_description("A"), "+0.2× multiplier")
		local j = fresh_jumble_state()
		G.TIMERS = { REAL = 0 }
		local result = effects.apply_word_effects("CAT", { modified_card("A") }, j, {})
		T.assert_equal(result.bonus_multi, 0.2)
		T.assert_equal(result.bonus_points, 0)
	end)

	T.it("A: adds +0.2× to puzzle score when modified A is played in a word with A", function()
		local rules = require("word_game.model.play.jumble_rules")
		G.GAME = G.GAME or {}
		G.GAME.word_round = { target = 100 }
		local j = fresh_jumble_state()
		local without = rules.preview_puzzle_total_after_word(j, "RATES", { modified_card("T") })
		local with_a = rules.preview_puzzle_total_after_word(j, "RATES", { modified_card("A") })
		T.assert_equal(without, 5, "RATES without modified A should score 5")
		T.assert_equal(with_a, 6, "RATES with modified A should score 6 (5 × 1.2)")
	end)

	T.it("A: does not apply without a modified A card in the word", function()
		local j = fresh_jumble_state()
		G.TIMERS = { REAL = 0 }
		local unmodified = { ability = { letter = "A", modified = false } }
		local result = effects.apply_word_effects("CAT", { unmodified }, j, {})
		T.assert_equal(result.bonus_multi, 0)
	end)

	T.it("E: description matches +1 bonus point when a modified E is played", function()
		T.assert_equal(deck.modifier_description("E"), "Gives +1 point.")
		local j = fresh_jumble_state()
		G.TIMERS = { REAL = 0 }
		local result = effects.apply_word_effects("PET", { modified_card("E") }, j, {})
		T.assert_equal(result.bonus_points, 1)
		T.assert_equal(result.bonus_multi, 0)
	end)

	T.it("E: adds +1 point to puzzle score when modified E is played in a word with E", function()
		local rules = require("word_game.model.play.jumble_rules")
		G.GAME = G.GAME or {}
		G.GAME.word_round = { target = 100 }
		local j = fresh_jumble_state()
		local without = rules.preview_puzzle_total_after_word(j, "PET", { modified_card("P") })
		local with_e = rules.preview_puzzle_total_after_word(j, "PET", { modified_card("E") })
		T.assert_equal(without, 3, "PET without modified E should score 3")
		T.assert_equal(with_e, 4, "PET with modified E should score 4 (3 + 1)")
	end)

	T.it("I: description matches +1 bonus point when a modified I is played", function()
		T.assert_equal(deck.modifier_description("I"), "Gives +1 point.")
		local j = fresh_jumble_state()
		G.TIMERS = { REAL = 0 }
		local result = effects.apply_word_effects("PIG", { modified_card("I") }, j, {})
		T.assert_equal(result.bonus_points, 1)
		T.assert_equal(result.bonus_multi, 0)
	end)

	T.it("I: adds +1 point to puzzle score when modified I is played in a word with I", function()
		local rules = require("word_game.model.play.jumble_rules")
		G.GAME = G.GAME or {}
		G.GAME.word_round = { target = 100 }
		local j = fresh_jumble_state()
		local without = rules.preview_puzzle_total_after_word(j, "PIG", { modified_card("P") })
		local with_i = rules.preview_puzzle_total_after_word(j, "PIG", { modified_card("I") })
		T.assert_equal(without, 3, "PIG without modified I should score 3")
		T.assert_equal(with_i, 4, "PIG with modified I should score 4 (3 + 1)")
	end)

	T.it("O: description matches +0.2× multiplier when a modified O is played", function()
		T.assert_equal(deck.modifier_description("O"), "+0.2× multiplier")
		local j = fresh_jumble_state()
		G.TIMERS = { REAL = 0 }
		local result = effects.apply_word_effects("DOG", { modified_card("O") }, j, {})
		T.assert_equal(result.bonus_multi, 0.2)
		T.assert_equal(result.bonus_points, 0)
		T.assert_equal(result.time_bonus, 0)
	end)

	T.it("O: adds +0.2× to puzzle score when modified O is played in a word with O", function()
		local rules = require("word_game.model.play.jumble_rules")
		G.GAME = G.GAME or {}
		G.GAME.word_round = { target = 100 }
		local without = rules.preview_puzzle_total_after_word(
			fresh_jumble_state(), "MOONS", { modified_card("M") })
		local with_o = rules.preview_puzzle_total_after_word(
			fresh_jumble_state(), "MOONS", { modified_card("O") })
		T.assert_equal(without, 5, "MOONS without modified O should score 5")
		T.assert_equal(with_o, 6, "MOONS with modified O should score 6 (5 × 1.2)")
	end)

	T.it("U: description matches +1 bonus point when a modified U is played", function()
		T.assert_equal(deck.modifier_description("U"), "Gives +1 point.")
		local j = fresh_jumble_state()
		G.TIMERS = { REAL = 0 }
		local result = effects.apply_word_effects("CUT", { modified_card("U") }, j, {})
		T.assert_equal(result.bonus_points, 1)
		T.assert_equal(result.bonus_multi, 0)
	end)

	T.it("U: adds +1 point to puzzle score when modified U is played in a word with U", function()
		local rules = require("word_game.model.play.jumble_rules")
		G.GAME = G.GAME or {}
		G.GAME.word_round = { target = 100 }
		local without = rules.preview_puzzle_total_after_word(
			fresh_jumble_state(), "CUT", { modified_card("C") })
		local with_u = rules.preview_puzzle_total_after_word(
			fresh_jumble_state(), "CUT", { modified_card("U") })
		T.assert_equal(without, 3, "CUT without modified U should score 3")
		T.assert_equal(with_u, 4, "CUT with modified U should score 4 (3 + 1)")
	end)
end)

T.describe("Modifier placement feedback (word_game.ui.modifier_feedback)", function()
	mock_env.reset_game()
	local feedback = require("word_game.ui.modifier_feedback")
	local float_up_text = require("word_game.ui.float_up_text")

	T.it("starts modifier float text above the card top edge", function()
		local captured
		local original_spawn = float_up_text.spawn
		float_up_text.spawn = function(config)
			captured = config
			return config
		end

		local card = { T = { x = 2, y = 4, w = 1, h = 1.4 } }
		float_up_text.from_card_above(card, "+1 point", { h = 0.5 })
		float_up_text.spawn = original_spawn

		T.assert_not_nil(captured, "modifier float text should be spawned")
		T.assert_true(captured.y + captured.h <= card.T.y + 0.001,
			"modifier float text should sit fully above the card top")
		T.assert_almost_equal(captured.y, card.T.y - 0.5 - 0.14, 0.01,
			"modifier float text should use the above-card gap offset")
	end)

	T.it("shows floating ui_text above a modified card placed in the row", function()
		local spawned = nil
		local original = float_up_text.from_card_above
		float_up_text.from_card_above = function(card, text, opts)
			spawned = { card = card, text = text, opts = opts }
		end
		local card = { ability = { letter = "I", modified = true }, T = { x = 2, y = 3, w = 1, h = 1.4 } }
		feedback.show_on_placed_card(card)
		float_up_text.from_card_above = original
		T.assert_not_nil(spawned)
		T.assert_equal(spawned.text, "+1 point")
		T.assert_equal(spawned.card, card)
	end)

	T.it("does not show feedback for unmodified cards", function()
		local spawned = false
		local original = float_up_text.from_card_above
		float_up_text.from_card_above = function()
			spawned = true
		end
		feedback.show_on_placed_card({ ability = { letter = "I", modified = false } })
		float_up_text.from_card_above = original
		T.assert_false(spawned)
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
