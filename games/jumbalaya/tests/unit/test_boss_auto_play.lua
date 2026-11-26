--[[ tests/unit/test_boss_auto_play.lua - Auto-submit boss word when hand is empty ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local shell = require("jumbalaya-engine.shell")
local Slots = require("jumbalaya_core.jumble.slots")

local function gardening_slots_filled()
	local puzzle = {
		kind = "rigid",
		pattern = "_AR_E_I_G",
		boss_word = "GARDENING",
		display = "_AR_E_I_G",
	}
	local slots = Slots.parse_slots(puzzle)
	for _, slot in ipairs(slots) do
		if slot.kind == "blank" then
			slot.card = { REMOVED = false, base = { value = "G" } }
		end
	end
	return slots, puzzle
end

local function boss_round_patch(slots, puzzle, extra)
	extra = extra or {}
	return {
		word_round = {
			mode = "jumble",
			set = 1,
			hand_index = 3,
			target = 2,
			jumble = {
				boss_word_active = true,
				boss_cards = { "b1", "b2", "b3", "b4" },
				slots = slots,
				puzzle = puzzle,
				total_score = 2,
			},
			score = extra.score or {},
		},
	}
end

T.describe("boss auto play after placement", function()
	T.it("should_auto_play_boss when boss hand empty and all blanks filled", function()
		mock_env.reset_game()
		local slots, puzzle = gardening_slots_filled()
		mock_env.patch_game(boss_round_patch(slots, puzzle))
		local game = shell.game()
		game.dealt_letters = game.dealt_letters or { cards = {} }
		game.dealt_letters.cards = {}

		local placement = require("word_game.ui.table.controls.placement")
		T.assert_true(placement.should_auto_play_boss(), "expect auto play when row complete and hand empty")
	end)

	T.it("should_auto_play_boss false while dealt hand still has cards", function()
		mock_env.reset_game()
		local slots, puzzle = gardening_slots_filled()
		mock_env.patch_game(boss_round_patch(slots, puzzle))
		local game = shell.game()
		game.dealt_letters = { cards = { { REMOVED = false } } }

		local placement = require("word_game.ui.table.controls.placement")
		T.assert_false(placement.should_auto_play_boss(), "wait until last card leaves hand")
	end)

	T.it("should_auto_play_boss false on non-boss hands", function()
		mock_env.reset_game()
		local slots, puzzle = gardening_slots_filled()
		mock_env.patch_game({
			word_round = {
				mode = "jumble",
				set = 1,
				hand_index = 1,
				jumble = {
					boss_word_active = false,
					slots = slots,
					puzzle = puzzle,
				},
			},
		})
		local game = shell.game()
		game.dealt_letters = { cards = {} }

		local placement = require("word_game.ui.table.controls.placement")
		T.assert_false(placement.should_auto_play_boss())
	end)

	T.it("invalid boss word does not deal cards back to hand", function()
		mock_env.reset_game()
		local Play = require("word_game.model.jumble_play")
		local slots, puzzle = gardening_slots_filled()
		-- Wrong letters on blanks → not GARDENING
		slots[1].card.base.value = "X"
		mock_env.patch_game(boss_round_patch(slots, puzzle))
		local game = shell.game()
		game.dealt_letters = { cards = {} }

		local result = Play.play_jumble_word()
		T.assert_equal(result.kind, "invalid")
		T.assert_equal(#game.dealt_letters.cards, 0, "hand stays empty after failed boss submit")
	end)
end)