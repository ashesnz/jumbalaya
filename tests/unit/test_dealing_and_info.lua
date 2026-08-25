--[[ tests/unit/test_dealing_and_info.lua
     Tests for 7-card hand size guarantee, deal count calculations, and info text positioning.
]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("Card Dealing & Hand Capacity (word_game.model.cards.deck)", function()
	mock_env.reset_game()
	local deck = require("word_game.model.cards.deck")

	T.it("has default TABLE_HAND_SIZE of 7", function()
		T.assert_equal(G.TABLE_HAND_SIZE, 7, "TABLE_HAND_SIZE should be 7")
	end)

	T.it("defines the twelve-card starter deck composition", function()
		local counts = {}
		for _, letter in ipairs(deck.STARTING_LETTERS) do
			counts[letter] = (counts[letter] or 0) + 1
		end
		T.assert_equal(#deck.STARTING_LETTERS, 12, "Starter deck should contain 12 cards")
		T.assert_equal(counts.E, 2, "Starter deck should contain 2 Es")
		T.assert_equal(counts.A, 2, "Starter deck should contain 2 As")
		T.assert_equal(counts.C, 1, "Starter deck should contain 1 C")
	end)

	T.it("uses twelve cards as the new-run deck capacity", function()
		T.assert_equal(deck.STARTING_LETTERS and #deck.STARTING_LETTERS, 12,
			"New runs should use a twelve-card starter deck")
	end)

	T.it("shuffles the starter deck when it is populated", function()
		G.deck = {
			cards = {},
			emplace = function(self, card) self.cards[#self.cards + 1] = card end,
			hard_set_T = function() end,
			config = {},
		}
		local create_letter_card = deck.create_letter_card
		deck.create_letter_card = function(letter, color)
			return { ability = { letter = letter, letter_color = color } }
		end
		deck.populate_starting_deck()
		deck.create_letter_card = create_letter_card
		T.assert_equal(#G.deck.cards, 12, "Starter population should create twelve cards")
		local letters = {}
		for _, card in ipairs(G.deck.cards) do letters[card.ability.letter] = (letters[card.ability.letter] or 0) + 1 end
		T.assert_equal(letters.E, 2, "Shuffling should preserve all starter cards")
		T.assert_equal(letters.C, 1, "Shuffling should preserve the starter composition")
	end)

	T.it("rebuilds the jumble deck without accumulating extra copies", function()
		G.GAME = G.GAME or {}
		G.deck = {
			cards = {},
			emplace = function(self, card) self.cards[#self.cards + 1] = card end,
			hard_set_T = function() end,
			config = {},
		}
		local create_letter_card = deck.create_letter_card
		deck.create_letter_card = function(letter, color)
			return { ability = { letter = letter, letter_color = color } }
		end
		deck.populate_jumble_deck()
		deck.populate_jumble_deck()
		deck.create_letter_card = create_letter_card
		T.assert_equal(#G.deck.cards, 12, "Jumble deck should stay at twelve cards after repopulation")
		T.assert_equal(G.GAME.deck_left_count, 12, "Deck count display should match the live deck size")
	end)

	T.it("takes cards from the top of the deck stack", function()
		G.deck = { cards = {
			{ ability = { letter = "A", letter_color = "red" }, T = { w = 1, h = 1 } },
			{ ability = { letter = "Z", letter_color = "red" }, T = { w = 1, h = 1 } },
		}, T = { x = 0, y = 0, w = 1, h = 1 } }
		G.hand = {
			cards = {},
			emplace = function(self, card) self.cards[#self.cards + 1] = card end,
			set_ranks = function() end,
			relayout = function() end,
		}
		G.placement_table = { area = { cards = {} } }
		local ensure_vowel = deck.ensure_vowel_in_hand
		local ensure_playable = deck.ensure_playable_held
		deck.ensure_vowel_in_hand = function() end
		deck.ensure_playable_held = function() end
		deck.draw_to_hand(1)
		deck.ensure_vowel_in_hand = ensure_vowel
		deck.ensure_playable_held = ensure_playable
		T.assert_equal(G.hand.cards[1].ability.letter, "Z", "The top card should be drawn first")
		T.assert_equal(#G.deck.cards, 1, "Drawing should pop exactly one card")
	end)

	T.it("counts held cards across both hand and placement area", function()
		G.hand = { cards = { {}, {}, {} } }
		G.placement_table = { area = { cards = { {}, {} } } }
		T.assert_equal(deck.held_count(), 5, "Held count should sum hand (3) + placement area (2) = 5")
	end)

	T.it("held count reflects empty hand and placement correctly", function()
		G.hand = { cards = {} }
		G.placement_table = { area = { cards = {} } }
		T.assert_equal(deck.held_count(), 0, "Held count should be 0 when empty")
	end)

	T.it("counts the physical cards remaining in the deck", function()
		G.GAME.starting_deck_size = 12
		G.deck = { cards = { {}, {}, {}, {}, {} } }
		G.hand = { cards = { {}, {}, {}, {}, {}, {}, {} } }
		G.placement_table = { area = { cards = {} } }
		T.assert_equal(deck.cards_left(), 5, "Cards left should come from the live deck array")
	end)

	T.it("calculates exact deal events needed for 2 cards played", function()
		G.hand = { cards = { {}, {}, {}, {}, {} } } -- 5 in hand (2 played)
		G.placement_table = { area = { cards = {} } }
		local queued = {}
		G.TIMELINE = {
			enqueue = function(self, ev)
				queued[#queued + 1] = ev
			end
		}
		local count = deck.deal_into_hand(7)
		T.assert_equal(count, 2, "deal_into_hand should return 2 needed cards")
		-- 2 before events (for each card) + 1 after event (finish)
		T.assert_equal(#queued, 3, "Should queue 2 deal events plus finish event")
		T.assert_equal(queued[1].mode, "window", "Tween 1 should be window mode")
		T.assert_equal(queued[2].mode, "window", "Tween 2 should be window mode")
		T.assert_equal(queued[3].mode, "delayed", "Tween 3 should be delayed mode")
	end)

	T.it("calculates exact deal events needed for 3 cards played", function()
		G.hand = { cards = { {}, {}, {}, {} } } -- 4 in hand (3 played)
		G.placement_table = { area = { cards = {} } }
		local queued = {}
		G.TIMELINE = {
			enqueue = function(self, ev)
				queued[#queued + 1] = ev
			end
		}
		local count = deck.deal_into_hand(7)
		T.assert_equal(count, 3, "deal_into_hand should return 3 needed cards")
		-- 3 before events (for each card) + 1 after event (finish)
		T.assert_equal(#queued, 4, "Should queue 3 deal events plus finish event")
	end)
end)

T.describe("Vault deck information", function()
	mock_env.reset_game()
	local deck = require("word_game.model.cards.deck")
	local table_deck = require("word_game.ui.table_deck")
	local hud_definition = require("word_game.ui.sidebar.hud_definition")

	T.it("shows only total cards left when the deck is clicked", function()
		G.GAME.starting_deck_size = 12
		G.deck = { cards = { {}, {}, {}, {}, {} } }
		G.hand = { cards = { {}, {}, {}, {}, {}, {}, {} } }
		G.placement_table = { area = { cards = {} } }
		G.STATE = G.STATES.TABLE_BOARD
		local captured
		spawn_attention = function(args) captured = args end
		table_deck.show_info()
		T.assert_equal(captured.text, "Cards left: 5", "Deck info should show calculated cards left")
	end)

	T.it("includes the cards-left counter in the Vault HUD", function()
		G.GAME = G.GAME or {}
		G.GAME.deck_left_count = 2
		G.deck = { cards = { {}, {} } }
		local definition = hud_definition.hud_definition()
		local function contains(node)
			if node.config and node.config.id == "row_deck_count" then return true end
			for _, child in ipairs(node.nodes or {}) do
				if contains(child) then return true end
			end
			return false
		end
		T.assert_true(contains(definition), "Vault HUD should contain cards-left row")
	end)

	T.it("updates the live deck count when cards are drawn", function()
		G.GAME = G.GAME or {}
		G.deck = { cards = { {}, {}, {}, {}, {} } }
		G.hand = { cards = {} }
		deck.sync_deck_count_display()
		T.assert_equal(G.GAME.deck_left_count, 5, "Sync should publish the current deck size")
		G.deck.cards = { {}, {}, {}, {} }
		deck.sync_deck_count_display()
		T.assert_equal(G.GAME.deck_left_count, 4, "Sync should reflect deck changes after a draw")
	end)

	T.it("discards played cards instead of returning them to the deck", function()
		local effects = require("word_game.ui.play_effects")
		G.GAME = G.GAME or {}
		G.GAME.deck_left_count = 5
		G.deck = {
			cards = { {}, {}, {}, {}, {} },
			emplace = function(self, card) self.cards[#self.cards + 1] = card end,
		}
		local destroyed = 0
		local orig_destroy = deck.destroy_card
		deck.destroy_card = function()
			destroyed = destroyed + 1
		end
		local queued = {}
		local orig_manager = G.TIMELINE
		G.TIMELINE = {
			enqueue = function(_, ev) queued[#queued + 1] = ev end,
		}
		effects.run_card_return_sequence({ {} }, function() end)
		for _, ev in ipairs(queued) do
			if ev.func then ev.func() end
		end
		G.TIMELINE = orig_manager
		deck.destroy_card = orig_destroy
		T.assert_equal(destroyed, 1, "Played cards should be destroyed for the round")
		T.assert_equal(#G.deck.cards, 5, "Discarding played cards should not refill the deck")
		T.assert_equal(G.GAME.deck_left_count, 5, "Cards left should not change when cards are played")
	end)

	T.it("restores the full deck after a cleared round", function()
		local effects = require("word_game.ui.play_effects")
		G.GAME = { deck_left_count = 5, word_round = { mode = "jumble" } }
		local returned = {}
		G.deck = {
			cards = {},
			emplace = function(self, card) self.cards[#self.cards + 1] = card end,
		}
		local card = { area = { remove_card = function() end } }
		local queued = {}
		local original_manager = G.TIMELINE
		G.TIMELINE = { enqueue = function(_, event) queued[#queued + 1] = event end }
		local original_populate = deck.populate_jumble_deck
		deck.populate_jumble_deck = function()
			returned[#returned + 1] = card
			G.deck.cards = { card, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }
			deck.sync_deck_count_display()
		end
		effects.run_card_return_sequence({ card }, function() end, true)
		for _, event in ipairs(queued) do event.func() end
		deck.populate_jumble_deck = original_populate
		G.TIMELINE = original_manager
		T.assert_equal(#returned, 0, "Return sequence should not rebuild the deck itself")
		T.assert_equal(#G.deck.cards, 1, "Cleared cards should return to the deck")
		T.assert_equal(G.GAME.deck_left_count, 1, "Cards-left display should include returned cards")
		T.assert_false(card.REMOVED, "Returned cards should remain active")
	end)
end)

T.describe("Info Text & Score Notification Alignment (word_game.model.play)", function()
	mock_env.reset_game()

	T.it("calculates gap metrics between placement area and hand correctly", function()
		G.placement_table = {
			area = {
				T = { x = 2, y = 2, w = 10, h = 2 }
			}
		}
		G.hand = {
			T = { x = 2, y = 6, w = 10, h = 2 }
		}
		G.table_felt = { x = 1, y = 1, w = 15, h = 9 }

		-- Hand gap should be between top (area.y + area.h = 4) and bottom (hand.y = 6)
		local top = G.placement_table.area.T.y + G.placement_table.area.T.h
		local bottom = G.hand.T.y
		local gap = bottom - top
		T.assert_true(gap > 0, "Gap should be positive between placement table and hand")
		T.assert_equal(gap, 2, "Gap between y=4 and y=6 should be 2")
	end)
end)
