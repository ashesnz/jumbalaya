--[[ tests/unit/test_debug_stage_jump.lua - Debug panel stage jump deals a fresh jumble hand ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("Debug stage jump (devtools.sections.stage)", function()
	mock_env.reset_game()

	local stage_section = require("devtools.sections.stage")
	local hand_size_cfg = require("word_game.model.hand_size")

	T.it("seeds seven bonus cards in the left gutter when jumping to stage 1-4", function()
		local created_letters = {}
		local promoted = nil
		local destroyed = 0
		local bonus_cards = {}

		WORD_GAME = WORD_GAME or {}
		WORD_GAME.Deck = {
			create_letter_card = function(letter)
				created_letters[#created_letters + 1] = letter
				return { ability = { letter = letter }, REMOVED = false }
			end,
			destroy_card = function()
				destroyed = destroyed + 1
			end,
		}
		WORD_GAME.BonusStackUI = {
			cards = function() return bonus_cards end,
			clear = function() bonus_cards = {} end,
			promote_to_bonus = function(cards)
				promoted = cards
				bonus_cards = cards
			end,
		}

		stage_section.seed_bonus_gutter()

		T.assert_equal(#created_letters, hand_size_cfg.get(),
			"Stage 1-4 debug should create seven bonus cards")
		T.assert_equal(#promoted, hand_size_cfg.get(),
			"Stage 1-4 debug should promote seven bonus cards")
		T.assert_equal(destroyed, 0, "No prior bonus cards should exist on first seed")
	end)
end)
