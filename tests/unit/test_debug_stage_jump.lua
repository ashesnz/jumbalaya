--[[ tests/unit/test_debug_stage_jump.lua - Debug panel stage jump deals a fresh jumble hand ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("Debug stage jump (devtools.sections.stage)", function()
	mock_env.reset_game()

	local stage_section = require("devtools.sections.stage")
	local DebugContext = require("devtools.context")
	local opening_deal = require("word_game.model.play.opening_deal")

	T.it("deals the opening hand after jumping to a jumble stage", function()
		local saved_word_game = WORD_GAME
		local saved_deal = opening_deal.deal

		G.STAGE = G.STAGES.RUN
		G.STATE = G.STATES.TABLE_BOARD
		G.GAME = G.GAME or {}
		G.GAME.alpha = { perks = {} }
		G.GAME.word_round = { set = 2, hand_index = 2, mode = "jumble", jumble = { total_score = 5 } }
		G.TABLE_HAND_SIZE = 7

		G.hand = {
			cards = { { ability = { letter = "Z" } } },
			emplace = function(self, card) self.cards[#self.cards + 1] = card end,
			remove_card = function(self, card)
				for i, c in ipairs(self.cards) do
					if c == card then
						table.remove(self.cards, i)
						return
					end
				end
			end,
			set_ranks = function() end,
			relayout = function() end,
			snap_VT = function() end,
			hard_set_cards = function() end,
		}
		G.deck = {
			cards = {},
			emplace = function(self, card) self.cards[#self.cards + 1] = card end,
			remove_card = function() return table.remove(G.deck.cards) end,
			hard_set_T = function() end,
			config = { card_limit = 12 },
		}
		G.playing_cards = {}
		for i = 1, 12 do
			local card = { ability = { letter = "A" }, REMOVED = false }
			G.playing_cards[#G.playing_cards + 1] = card
		end

		local start_calls = {}
		local opening_deal_called = false
		WORD_GAME = {
			Round = {
				start_hand = function(set, hand)
					start_calls[#start_calls + 1] = { set = set, hand = hand }
				end,
			},
			Deck = {
				reset_table_deck = function() end,
				populate_jumble_deck = function()
					G.hand.cards = {}
					G.deck.cards = {}
					for _, card in ipairs(G.playing_cards) do
						G.deck:emplace(card)
					end
				end,
				deal_jumble_hand = function()
					for _ = 1, 7 do
						local card = G.deck:remove_card()
						if card then
							G.hand:emplace(card)
						end
					end
				end,
			},
			Jumble = {
				is_active_hand = function() return true end,
				refresh_hud = function() end,
			},
			Sidebar = { refresh = function() end },
			PlayerHost = {
				dismiss_intro = function() end,
				end_stage3_cinematic = function() end,
				refresh_card_input = function() end,
			},
		}

		opening_deal.deal = function()
			opening_deal_called = true
			if WORD_GAME.Deck.populate_jumble_deck then
				WORD_GAME.Deck.populate_jumble_deck()
			end
			if WORD_GAME.Deck.deal_jumble_hand then
				WORD_GAME.Deck.deal_jumble_hand()
			end
		end

		stage_section.jump_to_hand(DebugContext.new(G), 1, 1)

		opening_deal.deal = saved_deal
		WORD_GAME = saved_word_game

		T.assert_equal(#start_calls, 1, "Should start the requested hand")
		T.assert_equal(start_calls[1].set, 1)
		T.assert_equal(start_calls[1].hand, 1)
		T.assert_true(opening_deal_called, "Stage jump must deal a fresh opening hand")
		T.assert_equal(#G.hand.cards, 7, "Jumble stage jump should leave seven cards in hand")
	end)
end)
