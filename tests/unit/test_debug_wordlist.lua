--[[ tests/unit/test_debug_wordlist.lua - Debug answer hints include gutter bonus cards ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("Debug wordlist answers", function()
	mock_env.reset_game()

	local jumble = require("word_game.model.jumble")

	local function mock_card(letter)
		return { ability = { letter = letter } }
	end

	T.it("includes active bonus-stack cards in debug answer counts", function()
		G.hand = { cards = { mock_card("A"), mock_card("T") } }
		G.placement_table = { area = { cards = { mock_card("E") } } }
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.BonusStack = {
			is_active = function() return true end,
			cards = function()
				return { mock_card("B"), mock_card("O"), mock_card("N") }
			end,
		}
		Dictionary = {
			counts_from_cards = function(cards)
				local counts = {}
				for _, card in ipairs(cards) do
					local letter = card.ability.letter
					counts[letter] = (counts[letter] or 0) + 1
				end
				return counts
			end,
		}

		local cards = jumble.debug_answer_cards()
		T.assert_equal(#cards, 6, "Should count hand, placement, and gutter bonus cards")

		local counts = jumble.debug_answer_counts()
		T.assert_equal(counts.A, 1)
		T.assert_equal(counts.T, 1)
		T.assert_equal(counts.E, 1)
		T.assert_equal(counts.B, 1)
		T.assert_equal(counts.O, 1)
		T.assert_equal(counts.N, 1)
	end)

	T.it("does not double-count bonus cards placed in the puzzle row", function()
		local placed = mock_card("R")
		G.hand = { cards = { mock_card("C") } }
		G.placement_table = { area = { cards = { placed } } }
		placed.area = G.placement_table.area
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.BonusStack = {
			is_active = function() return true end,
			cards = function() return { placed, mock_card("Z") } end,
		}
		Dictionary = {
			counts_from_cards = function(cards)
				local counts = {}
				for _, card in ipairs(cards) do
					local letter = card.ability.letter
					counts[letter] = (counts[letter] or 0) + 1
				end
				return counts
			end,
		}

		local counts = jumble.debug_answer_counts()
		T.assert_equal(counts.C, 1)
		T.assert_equal(counts.R, 1)
		T.assert_equal(counts.Z, 1)
	end)

	T.it("skips bonus-stack cards when the gutter stack is inactive", function()
		G.hand = { cards = { mock_card("C") } }
		G.placement_table = { area = { cards = {} } }
		WORD_GAME = WORD_GAME or {}
		WORD_GAME.BonusStack = {
			is_active = function() return false end,
			cards = function() return { mock_card("Z") } end,
		}
		Dictionary = {
			counts_from_cards = function(cards)
				local counts = {}
				for _, card in ipairs(cards) do
					local letter = card.ability.letter
					counts[letter] = (counts[letter] or 0) + 1
				end
				return counts
			end,
		}

		T.assert_equal(#jumble.debug_answer_cards(), 1)
		T.assert_nil(jumble.debug_answer_counts().Z)
	end)
end)
