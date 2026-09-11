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
		G.draw_pile = {
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
		local TableAreas = require("word_game.model.table_areas")
		T.assert_equal(#TableAreas.draw_cards(), 12, "Starter population should create twelve cards")
		local letters = {}
		for _, card in ipairs(TableAreas.draw_cards()) do letters[card.ability.letter] = (letters[card.ability.letter] or 0) + 1 end
		T.assert_equal(letters.E, 2, "Shuffling should preserve all starter cards")
		T.assert_equal(letters.C, 1, "Shuffling should preserve the starter composition")
	end)

	T.it("rebuilds the jumble deck without accumulating extra copies", function()
		G.GAME = G.GAME or {}
		G.draw_pile = {
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
		local TableAreas = require("word_game.model.table_areas")
		T.assert_equal(#TableAreas.draw_cards(), 12, "Jumble deck should stay at twelve cards after repopulation")
		T.assert_equal(G.GAME.deck_left_count, 12, "Deck count display should match the live deck size")
	end)

	T.it("takes cards from the top of the deck stack", function()
		mock_env.clear_store_piles()
		G.draw_pile = { cards = {
			{ ability = { letter = "A", letter_color = "red" }, T = { w = 1, h = 1 } },
			{ ability = { letter = "Z", letter_color = "red" }, T = { w = 1, h = 1 } },
		}, T = { x = 0, y = 0, w = 1, h = 1 } }
		G.dealt_letters = {
			cards = {},
			emplace = function(self, card) self.cards[#self.cards + 1] = card end,
			set_ranks = function() end,
			relayout = function() end,
		}
		G.pattern_row = { area = { cards = {} } }
		local ensure_vowel = deck.ensure_vowel_in_hand
		local ensure_playable = deck.ensure_playable_held
		deck.ensure_vowel_in_hand = function() end
		deck.ensure_playable_held = function() end
		deck.draw_to_hand(1)
		deck.ensure_vowel_in_hand = ensure_vowel
		deck.ensure_playable_held = ensure_playable
		local TableAreas = require("word_game.model.table_areas")
		T.assert_equal(TableAreas.hand_cards()[1].ability.letter, "Z", "The top card should be drawn first")
		T.assert_equal(#TableAreas.draw_cards(), 1, "Drawing should pop exactly one card")
	end)

	T.it("counts held cards across both hand and placement area", function()
		mock_env.clear_store_piles()
		G.dealt_letters = { cards = { {}, {}, {} } }
		G.pattern_row = { area = { cards = { {}, {} } } }
		T.assert_equal(deck.held_count(), 5, "Held count should sum hand (3) + placement area (2) = 5")
	end)

	T.it("held count reflects empty hand and placement correctly", function()
		mock_env.clear_store_piles()
		G.dealt_letters = { cards = {} }
		G.pattern_row = { area = { cards = {} } }
		T.assert_equal(deck.held_count(), 0, "Held count should be 0 when empty")
	end)

	T.it("counts the physical cards remaining in the deck", function()
		mock_env.clear_store_piles()
		G.GAME.starting_deck_size = 12
		G.draw_pile = { cards = { {}, {}, {}, {}, {} } }
		G.dealt_letters = { cards = { {}, {}, {}, {}, {}, {}, {} } }
		G.pattern_row = { area = { cards = {} } }
		T.assert_equal(deck.cards_left(), 5, "Cards left should come from the live deck array")
	end)

	T.it("calculates exact deal events needed for 2 cards played", function()
		mock_env.clear_store_piles()
		G.dealt_letters = { cards = { {}, {}, {}, {}, {} } } -- 5 in hand (2 played)
		G.pattern_row = { area = { cards = {} } }
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
		mock_env.clear_store_piles()
		G.dealt_letters = { cards = { {}, {}, {}, {} } } -- 4 in hand (3 played)
		G.pattern_row = { area = { cards = {} } }
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

T.describe("Sidebar deck information", function()
	mock_env.reset_game()
	local deck = require("word_game.model.cards.deck")
	local table_deck = require("word_game.ui.table.deck")
	local hud_layout = require("word_game.ui.sidebar.hud_layout")

	T.it("shows only total cards left when the deck is clicked", function()
		G.GAME.starting_deck_size = 12
		G.draw_pile = { cards = { {}, {}, {}, {}, {} } }
		G.dealt_letters = { cards = { {}, {}, {}, {}, {}, {}, {} } }
		G.pattern_row = { area = { cards = {} } }
		G.STATE = G.STATES.TABLE_BOARD
		local captured
		spawn_attention = function(args) captured = args end
		table_deck.show_info()
		T.assert_equal(captured.text, "Cards left: 5", "Deck info should show calculated cards left")
	end)

	T.it("includes the cards-left counter in the Sidebar HUD", function()
		G.GAME = G.GAME or {}
		G.GAME.deck_left_count = 2
		G.draw_pile = { cards = { {}, {} } }
		local layout = hud_layout.compute()
		T.assert_not_nil(layout.deck_count, "Sidebar HUD should contain cards-left row")
	end)

	T.it("updates the live deck count when cards are drawn", function()
		G.GAME = G.GAME or {}
		G.draw_pile = { cards = { {}, {}, {}, {}, {} } }
		G.dealt_letters = { cards = {} }
		deck.sync_deck_count_display()
		T.assert_equal(G.ARGS.deck_left_count, 5, "Sync should publish the current deck size")
		G.draw_pile.cards = { {}, {}, {}, {} }
		deck.sync_deck_count_display()
		T.assert_equal(G.ARGS.deck_left_count, 4, "Sync should reflect deck changes after a draw")
		T.assert_equal(G.GAME.deck_left_count, 4, "G.GAME mirror should follow cards left")
	end)

	T.it("sends played cards to the hidden played pool during jumble word plays", function()
		local effects = require("word_game.ui.play_effects")
		G.GAME = G.GAME or {}
		G.GAME.deck_left_count = 5
		G.recycle_stash = {
			cards = {},
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
		T.assert_equal(#G.recycle_stash.cards, 1, "Used cards should enter the played pool")
		T.assert_true(G.recycle_stash.cards[1].played_pool, "Played cards should be tagged for hidden storage")
	end)

	T.it("keeps the full deck count when advancing through jumble stages", function()
		local effects = require("word_game.ui.play_effects")
		local jumble = require("word_game.model.jumble")

		local cards = {}
		G.letter_inventory = {}
		G.draw_pile = {
			cards = cards,
			config = { card_limit = 52 },
			emplace = function(self, card) table.insert(self.cards, card) end,
			remove_card = function(self) return table.remove(self.cards) end,
			shuffle = function() end,
			hard_set_T = function() end,
		}
		G.dealt_letters = {
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
		G.recycle_stash = {
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
		G.pattern_row = {
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

			T.assert_equal(#G.letter_inventory, expected,
				"Stage 1-" .. hand_index .. " should retain every deck card")
			T.assert_equal(deck.cards_left() + deck.held_count(), expected,
				"Stage 1-" .. hand_index .. " deck plus held cards should equal the full deck")

			for _ = 1, 3 do
				local used = {}
				if G.dealt_letters.cards[1] then
					used[#used + 1] = G.dealt_letters.cards[1]
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
		T.assert_equal(#G.letter_inventory, expected,
			"Advancing to stage 1-5 should leave the full starter deck intact")
		T.assert_equal(deck.cards_left(), expected,
			"Stage 1-5 should start with the full deck count after repopulation")
	end)

	T.it("reports jumble cards left as the physical draw pile count", function()
		mock_env.clear_store_piles()
		G.GAME.word_round = { mode = "jumble", set = 1, hand_index = 1 }
		G.letter_inventory = {}
		for i = 1, 12 do
			G.letter_inventory[#G.letter_inventory + 1] = { ability = { letter = "E" } }
		end
		G.dealt_letters = { cards = {} }
		for i = 1, 7 do
			G.dealt_letters.cards[#G.dealt_letters.cards + 1] = G.letter_inventory[i]
		end
		G.draw_pile = { cards = {} }
		for i = 8, 12 do
			G.draw_pile.cards[#G.draw_pile.cards + 1] = G.letter_inventory[i]
		end
		G.pattern_row = { area = { cards = {} } }
		T.assert_equal(deck.cards_left(), 5, "Cards left should match cards still in the draw pile")
		T.assert_equal(deck.draw_pile_count(), 5, "Draw pile should track physical deck cards")

		G.dealt_letters.cards[#G.dealt_letters.cards + 1] = table.remove(G.draw_pile.cards)
		deck.sync_deck_count_display()
		T.assert_equal(deck.cards_left(), 4, "Drawing into hand should decrement cards left")
		T.assert_equal(G.ARGS.deck_left_count, 4, "HUD counter should follow cards left")
		T.assert_equal(G.GAME.deck_left_count, 4, "G.GAME mirror should follow cards left")
	end)

	T.it("sidebar HUD cards-left matches the physical deck after jumble deal", function()
		G.GAME.word_round = { mode = "jumble", set = 1, hand_index = 1 }
		G.letter_inventory = {}
		G.draw_pile = {
			cards = {},
			emplace = function(self, card) self.cards[#self.cards + 1] = card end,
			remove_card = function(self) return table.remove(self.cards) end,
			config = {},
			hard_set_T = function() end,
		}
		G.dealt_letters = {
			cards = {},
			emplace = function(self, card) self.cards[#self.cards + 1] = card end,
			set_ranks = function() end,
			relayout = function() end,
			snap_VT = function() end,
			hard_set_cards = function() end,
		}
		G.recycle_stash = { cards = {} }
		G.pattern_row = { area = { cards = {}, hard_set_cards = function() end } }
		local create_letter_card = deck.create_letter_card
		deck.create_letter_card = function(letter, color)
			return { ability = { letter = letter, letter_color = color } }
		end
		deck.populate_jumble_deck()
		deck.create_letter_card = create_letter_card

		G.ARGS = G.ARGS or {}
		G.ARGS.deck_left_count = 0
		deck.sync_deck_count_display()
		T.assert_equal(G.ARGS.deck_left_count, #deck.STARTING_LETTERS,
			"HUD build should sync cards left to the full draw pile before dealing")
		T.assert_equal(G.GAME.deck_left_count, #deck.STARTING_LETTERS,
			"G.GAME mirror should match the draw pile before dealing")

		deck.deal_jumble_hand()
		deck.sync_deck_count_display()
		local TableAreas = require("word_game.model.table_areas")
		local expected = #TableAreas.draw_cards()
		T.assert_equal(G.ARGS.deck_left_count, expected,
			"HUD counter should match the physical draw pile after dealing")
		T.assert_equal(G.GAME.deck_left_count, expected,
			"G.GAME mirror should match the physical draw pile after dealing")
		T.assert_equal(deck.cards_left(), expected,
			"cards_left should match the physical draw pile after dealing")
	end)

	T.it("sidebar HUD text node reads G.ARGS even when G.GAME is replaced", function()
		mock_env.clear_store_piles()
		mock_env.ensure_engine_globals()
		require("jumbalaya-engine.retained_ui")
		G.LANG = G.LANG or {
			font = {
				FONT = love.graphics.newFont(12),
				FONTSCALE = 0.12,
				squish = 1,
				TEXT_HEIGHT_SCALE = 0.7,
				TEXT_OFFSET = { x = 0, y = 0 },
			},
		}
		G.C.UI = G.C.UI or { TEXT_LIGHT = { 1, 1, 1, 1 } }
		G.UI = G.UI or { ROOT = 1, ROW = 2, TEXT = 4 }
		G.TILESCALE = G.TILESCALE or 1
		G.TILESIZE = G.TILESIZE or 20
		G.UI.padding = G.UI.padding or 0.1
		G.SIDEBAR_ATTACH = G.SIDEBAR_ATTACH or { T = { x = 17, y = 0, w = 3, h = 10 } }

		local stale_game = { deck_left_count = 0 }
		G.GAME = stale_game
		G.draw_pile = { cards = { {}, {}, {}, {}, {} } }
		G.dealt_letters = { cards = { {}, {}, {}, {}, {}, {}, {} } }
		G.pattern_row = { area = { cards = {} } }
		deck.sync_deck_count_display()
		T.assert_equal(G.ARGS.deck_left_count, 5, "Sync should publish the live draw pile count")

		local SidebarView = require("word_game.ui.views.sidebar_view")
		local Store = require("jumbalaya_core.store")
		local view = SidebarView.new({ store = Store.new() })
		view:recalculate()

		local text_node = view:find_node_by_id("text_deck_count")
		T.assert_not_nil(text_node, "Sidebar HUD should contain the cards-left ref text node")
		text_node:update_text()
		T.assert_equal(text_node.config.text, "5",
			"Rendered cards-left text should match the physical draw pile")

		G.GAME = { deck_left_count = 0 }
		text_node:update_text()
		T.assert_equal(text_node.config.text, "5",
			"Cards-left text must stay bound to G.ARGS when G.GAME is replaced")

		G.draw_pile.cards = { {}, {}, {} }
		deck.sync_deck_count_display()
		text_node:update_text()
		T.assert_equal(text_node.config.text, "3",
			"Cards-left text should refresh when the draw pile changes")

		view:remove()
	end)

	T.it("reshuffles discard into deck and deals seven when hand and deck are empty", function()
		mock_env.clear_store_piles()
		G.GAME.word_round = { mode = "jumble", set = 1, hand_index = 1 }
		G.dealt_letters = {
			cards = {},
			emplace = function(self, card) self.cards[#self.cards + 1] = card end,
			set_ranks = function() end,
			relayout = function() end,
			snap_VT = function() end,
			hard_set_cards = function() end,
		}
		G.draw_pile = {
			cards = {},
			emplace = function(self, card) self.cards[#self.cards + 1] = card end,
			remove_card = function(self) return table.remove(self.cards) end,
			config = {},
		}
		G.recycle_stash = {
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
		G.pattern_row = { area = { cards = {} } }
		G.letter_inventory = {}
		for i = 1, 12 do
			local card = { ability = { letter = "E", letter_color = "red" } }
			G.letter_inventory[#G.letter_inventory + 1] = card
			G.recycle_stash:emplace(card)
		end
		local orig_jumble = WORD_GAME and WORD_GAME.Jumble
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.Jumble = { ensure_playable_puzzle = function() return true end }

		T.assert_true(deck.try_jumble_reshuffle_and_deal())
		T.assert_equal(#G.recycle_stash.cards, 0, "Discard pile should be empty after recycle")
		local TableAreas = require("word_game.model.table_areas")
		T.assert_equal(#TableAreas.hand_cards(), 7, "Player should receive a full hand of seven cards")
		T.assert_equal(#TableAreas.draw_cards(), 5, "Remaining cards should stay in the deck")
		T.assert_equal(deck.cards_left(), 5, "Cards left should match the physical draw pile")

		WORD_GAME.Jumble = orig_jumble
	end)

	T.it("keeps the discard voucher fill count when recycling into the deck", function()
		if not require("word_game.ui.perks.discard_bin").voucher_discard_unlocked() then return end
		local table_discard = require("word_game.ui.perks.discard_bin")
		G.STATE = G.STATES.MENU or 2
		G.GAME = { run_state = { perks = { "discard_bin" } } }
		G.RUN = { active = true }
		table_discard.reset()
		table_discard.record_discard()
		table_discard.record_discard()
		T.assert_equal(table_discard.fill_count(), 2)

		G.GAME = G.GAME or {}
		G.GAME.word_round = { mode = "jumble", set = 1, hand_index = 1 }
		G.dealt_letters = {
			cards = {},
			emplace = function(self, card) self.cards[#self.cards + 1] = card end,
			set_ranks = function() end,
			relayout = function() end,
			snap_VT = function() end,
			hard_set_cards = function() end,
		}
		G.draw_pile = {
			cards = {},
			emplace = function(self, card) self.cards[#self.cards + 1] = card end,
			remove_card = function(self) return table.remove(self.cards) end,
			config = {},
		}
		G.recycle_stash = {
			cards = { { ability = { letter = "E" } } },
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
		G.pattern_row = { area = { cards = {} } }
		G.letter_inventory = G.recycle_stash.cards

		deck.try_jumble_reshuffle_and_deal()

		T.assert_equal(table_discard.fill_count(), 2, "Discard fill should persist across reshuffle")
		T.assert_equal(G.GAME.discard_bin_count, 2, "Bin count should stay on G.GAME")
	end)

	T.it("does not reshuffle while cards remain in hand, deck, or placement", function()
		G.GAME.word_round = { mode = "jumble", set = 1, hand_index = 1 }
		G.dealt_letters = { cards = { { ability = { letter = "A" } } } }
		G.draw_pile = { cards = { { ability = { letter = "C" } } } }
		G.recycle_stash = { cards = { { ability = { letter = "B" } } } }
		G.pattern_row = { area = { cards = {} } }
		T.assert_false(deck.needs_jumble_reshuffle(), "Hand still has cards")

		G.dealt_letters.cards = {}
		T.assert_false(deck.needs_jumble_reshuffle(), "Deck still has cards")

		G.draw_pile.cards = {}
		G.pattern_row.area.cards = { { ability = { letter = "D" } } }
		T.assert_false(deck.needs_jumble_reshuffle(), "Placement still has cards")
	end)

	T.it("keeps the sidebar deck image visible when cards left reaches zero", function()
		mock_env.reset_game()
		G.STATE = G.STATES.TABLE_BOARD
		G.STAGE = G.STAGES.RUN
		G.draw_pile = {
			cards = {},
			T = { x = 12, y = 4, w = 2.4, h = 1.8 },
			translate_container = function() end,
			draw = function() end,
		}
		G.ARGS = G.ARGS or {}
		deck.sync_deck_count_display()
		T.assert_equal(deck.cards_left(), 0)
		T.assert_equal(G.ARGS.deck_left_count, 0)

		local table_deck = require("word_game.ui.table.deck")
		T.assert_true(table_deck.pack_stack_height(0) > 0,
			"Empty draw pile should still reserve visible pack height in the sidebar")

		local table_board = require("word_game.ui.table.board")
		T.assert_true(table_board.should_draw_sidebar_deck(),
			"Sidebar deck pile should still draw at zero cards left")
	end)
end)

T.describe("Info Text & Score Notification Alignment (word_game.model.jumble_play)", function()
	mock_env.reset_game()

	T.it("calculates gap metrics between placement area and hand correctly", function()
		G.pattern_row = {
			area = {
				T = { x = 2, y = 2, w = 10, h = 2 }
			}
		}
		G.dealt_letters = {
			T = { x = 2, y = 6, w = 10, h = 2 }
		}
		G.table_felt = { x = 1, y = 1, w = 15, h = 9 }

		-- Hand gap should be between top (area.y + area.h = 4) and bottom (hand.y = 6)
		local top = G.pattern_row.area.T.y + G.pattern_row.area.T.h
		local bottom = G.dealt_letters.T.y
		local gap = bottom - top
		T.assert_true(gap > 0, "Gap should be positive between placement table and hand")
		T.assert_equal(gap, 2, "Gap between y=4 and y=6 should be 2")
	end)
end)
