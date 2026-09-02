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

	T.it("returns played cards to the deck during jumble word plays", function()
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
		local card = { area = { remove_card = function() end } }
		effects.run_card_return_sequence({ card }, function() end, true)
		for _, ev in ipairs(queued) do
			if ev.func then ev.func() end
		end
		G.TIMELINE = orig_manager
		deck.destroy_card = orig_destroy
		T.assert_equal(destroyed, 0, "Jumble word plays should not destroy used cards")
		T.assert_equal(#G.deck.cards, 6, "Used cards should return to the deck pile")
		T.assert_equal(G.GAME.deck_left_count, 6, "Cards-left display should include returned cards")
		T.assert_false(card.REMOVED, "Returned cards should remain active")
	end)

	T.it("keeps the full deck count when advancing through jumble stages", function()
		local effects = require("word_game.ui.play_effects")
		local jumble = require("word_game.model.jumble")

		local cards = {}
		G.playing_cards = {}
		G.deck = {
			cards = cards,
			config = { card_limit = 52 },
			emplace = function(self, card) table.insert(self.cards, card) end,
			remove_card = function(self) return table.remove(self.cards) end,
			shuffle = function() end,
			hard_set_T = function() end,
		}
		G.hand = {
			cards = {},
			config = {},
			emplace = function(self, card) table.insert(self.cards, card) end,
			remove_card = function(self, card)
				for i, c in ipairs(self.cards) do
					if c == card then
						table.remove(self.cards, i)
						break
					end
				end
			end,
			set_ranks = function() end,
			relayout = function() end,
			snap_VT = function() end,
			hard_set_cards = function() end,
		}
		G.discard = {
			cards = {},
			emplace = function(self, card) table.insert(self.cards, card) end,
			remove_card = function(self, card)
				for i, c in ipairs(self.cards) do
					if c == card then
						table.remove(self.cards, i)
						break
					end
				end
			end,
			hard_set_cards = function() end,
		}
		G.placement_table = {
			area = {
				cards = {},
				emplace = function(self, card) table.insert(self.cards, card) end,
				remove_card = function(self, card)
					for i, c in ipairs(self.cards) do
						if c == card then
							table.remove(self.cards, i)
							break
						end
					end
				end,
				hard_set_cards = function() end,
			},
			on_remove_card = function() end,
		}
		G.GAME.deck_alpha = { pos = { x = 0, y = 0 } }

		deck.populate_starting_deck()
		local expected = #deck.STARTING_LETTERS
		local orig_ensure = jumble.ensure_playable_puzzle
		jumble.ensure_playable_puzzle = function() return true end

		local function drain_timeline(queued)
			for _, ev in ipairs(queued) do
				if ev.func then ev.func() end
			end
		end

		for hand_index = 1, 5 do
			G.GAME.word_round = {
				set = 1,
				hand_index = hand_index,
				mode = "jumble",
				target = 9999,
				played_words = {},
			}
			deck.populate_jumble_deck()
			deck.deal_jumble_hand()

			T.assert_equal(#G.playing_cards, expected,
				"Stage 1-" .. hand_index .. " should retain every deck card")
			T.assert_equal(deck.cards_left() + deck.held_count(), expected,
				"Stage 1-" .. hand_index .. " deck plus held cards should equal the full deck")

			for _ = 1, 3 do
				local used = {}
				if G.hand.cards[1] then
					used[#used + 1] = G.hand.cards[1]
				end
				local queued = {}
				local orig_manager = G.TIMELINE
				G.TIMELINE = { enqueue = function(_, ev) queued[#queued + 1] = ev end }
				effects.run_card_return_sequence(used, function() end, true)
				drain_timeline(queued)
				G.TIMELINE = orig_manager
			end

			deck.populate_jumble_deck()
		end

		jumble.ensure_playable_puzzle = orig_ensure
		T.assert_equal(#G.playing_cards, expected,
			"Advancing to stage 1-5 should leave the full starter deck intact")
		T.assert_equal(deck.cards_left(), expected,
			"Stage 1-5 should start with the full deck count after repopulation")
	end)

	T.it("reports jumble cards left as pool size minus hand size", function()
		G.GAME.word_round = { mode = "jumble", set = 1, hand_index = 1 }
		G.playing_cards = {}
		for i = 1, 12 do
			G.playing_cards[#G.playing_cards + 1] = { ability = { letter = "E" } }
		end
		G.hand = { cards = {} }
		for i = 1, 7 do
			G.hand.cards[#G.hand.cards + 1] = G.playing_cards[i]
		end
		G.deck = { cards = {} }
		for i = 8, 12 do
			G.deck.cards[#G.deck.cards + 1] = G.playing_cards[i]
		end
		G.placement_table = { area = { cards = {} } }
		T.assert_equal(deck.cards_left(), 5, "Cards left should be total pool minus hand")
		T.assert_equal(deck.draw_pile_count(), 5, "Draw pile should still track physical deck cards")

		G.hand.cards[#G.hand.cards + 1] = table.remove(G.deck.cards)
		deck.sync_deck_count_display()
		T.assert_equal(deck.cards_left(), 4, "Drawing into hand should decrement cards left")
		T.assert_equal(G.GAME.deck_left_count, 4, "HUD counter should follow cards left")
	end)

	T.it("reshuffles discard into deck and deals seven when hand and deck are empty", function()
		G.GAME.word_round = { mode = "jumble", set = 1, hand_index = 1 }
		G.hand = {
			cards = {},
			emplace = function(self, card) self.cards[#self.cards + 1] = card end,
			set_ranks = function() end,
			relayout = function() end,
			snap_VT = function() end,
			hard_set_cards = function() end,
		}
		G.deck = {
			cards = {},
			emplace = function(self, card) self.cards[#self.cards + 1] = card end,
			remove_card = function(self) return table.remove(self.cards) end,
			config = {},
		}
		G.discard = {
			cards = {},
			emplace = function(self, card) self.cards[#self.cards + 1] = card end,
			remove_card = function(self, card)
				for i, c in ipairs(self.cards) do
					if c == card then
						table.remove(self.cards, i)
						return card
					end
				end
			end,
			hard_set_cards = function() end,
		}
		G.placement_table = { area = { cards = {} } }
		G.playing_cards = {}
		for i = 1, 12 do
			local card = { ability = { letter = "E", letter_color = "red" } }
			G.playing_cards[#G.playing_cards + 1] = card
			G.discard:emplace(card)
		end
		local orig_jumble = WORD_GAME and WORD_GAME.Jumble
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.Jumble = { ensure_playable_puzzle = function() return true end }
		WORD_GAME.TableDiscard = { reset = function() end }

		T.assert_true(deck.try_jumble_reshuffle_and_deal())
		T.assert_equal(#G.discard.cards, 0, "Discard pile should be empty after recycle")
		T.assert_equal(#G.hand.cards, 7, "Player should receive a full hand of seven cards")
		T.assert_equal(#G.deck.cards, 5, "Remaining cards should stay in the deck")
		T.assert_equal(deck.cards_left(), 5, "Cards left should be pool minus the new hand")

		WORD_GAME.Jumble = orig_jumble
	end)

	T.it("does not reshuffle while cards remain in hand, deck, or placement", function()
		G.GAME.word_round = { mode = "jumble", set = 1, hand_index = 1 }
		G.hand = { cards = { { ability = { letter = "A" } } } }
		G.deck = { cards = { { ability = { letter = "C" } } } }
		G.discard = { cards = { { ability = { letter = "B" } } } }
		G.placement_table = { area = { cards = {} } }
		T.assert_false(deck.needs_jumble_reshuffle(), "Hand still has cards")

		G.hand.cards = {}
		T.assert_false(deck.needs_jumble_reshuffle(), "Deck still has cards")

		G.deck.cards = {}
		G.placement_table.area.cards = { { ability = { letter = "D" } } }
		T.assert_false(deck.needs_jumble_reshuffle(), "Placement still has cards")
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
