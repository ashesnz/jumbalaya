--[[ tests/unit/test_bonus_cards.lua - Stage 1-4 bonus card rules ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("Bonus cards", function()
	mock_env.reset_game()
	local bonus_stack = require("word_game.ui.boss_word_stack")
	local jumble = require("word_game.model.jumble")

	local function mock_card(letter)
		return {
			ability = { letter = letter, bonus = 0 },
			T = { x = 0, y = 0, w = 2, h = 2.8, r = 0 },
			states = { drag = { can = true, is = false }, collide = { can = true } },
			hard_set_T = function(self, x, y, w, h)
				self.T.x, self.T.y, self.T.w, self.T.h = x, y, w, h
			end,
		}
	end

	T.it("promotes boss word cards to one-time +10 bonus cards", function()
		bonus_stack.clear()
		local cards = { mock_card("C"), mock_card("A"), mock_card("T") }
		bonus_stack.promote_to_bonus(cards)
		T.assert_true(bonus_stack.is_active())
		T.assert_equal(#bonus_stack.cards(), 3)
		for _, card in ipairs(cards) do
			T.assert_true(card.bonus_card)
			T.assert_nil(card.boss_temp)
			T.assert_equal(card.ability.bonus, bonus_stack.BONUS_POINTS)
		end
	end)

	T.it("adds +10 per bonus card used in puzzle scoring", function()
		local wr = {
			mode = "jumble",
			jumble = {
				puzzle_index = 1,
				solved = false,
				puzzle_points = 0,
				puzzle_multi = 1.0,
				puzzle_words = {},
				slots = {},
				puzzle = { span = { "C", "T" }, min = 3, max = 7, kind = "span" },
			},
		}
		G.GAME.word_round = wr
		local bonus = mock_card("A")
		bonus.bonus_card = true
		local _, new_pts = jumble.record_puzzle_word("CAT", { used_cards = { bonus } })
		T.assert_equal(new_pts, 3 + bonus_stack.BONUS_POINTS)
	end)

	T.it("keeps bonus cards when entering stage 1-4 and clears them later", function()
		bonus_stack.clear()
		bonus_stack.promote_to_bonus({ mock_card("Z") })
		bonus_stack.on_hand_start(1, 4)
		T.assert_true(bonus_stack.is_active())
		bonus_stack.on_hand_start(2, 1)
		T.assert_false(bonus_stack.is_active())
	end)

	T.it("excludes bonus cards from jumble deck population", function()
		mock_env.reset_game()
		local deck_mod = require("word_game.model.cards.deck")
		G.playing_cards = {
			{ REMOVED = false, boss_temp = false, bonus_card = false },
			{ REMOVED = false, bonus_card = true },
		}
		G.deck = {
			cards = {},
			config = { card_limit = 0 },
			emplace = function(self, card) self.cards[#self.cards + 1] = card end,
			hard_set_T = function() end,
		}
		G.hand = { cards = {}, remove_card = function() end }
		G.placement_table = { area = { cards = {}, hard_set_cards = function() end } }
		deck_mod.populate_jumble_deck()
		T.assert_equal(#G.deck.cards, 1)
	end)
end)
