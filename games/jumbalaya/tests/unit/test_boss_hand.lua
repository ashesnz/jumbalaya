--[[ tests/unit/test_boss_hand.lua — boss_hand_letters, staging clear, deal + store ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local shell = require("jumbalaya-engine.shell")
local core_env = require("tests.helpers.core_env")

local PuzzleSpec = require("jumbalaya_core.jumble.puzzle_spec")

local function sorted_multiset(letters)
	local copy = {}
	for index, letter in ipairs(letters) do
		copy[index] = letter
	end
	table.sort(copy)
	return copy
end

local function assert_same_multiset(T, left, right)
	local a = sorted_multiset(left)
	local b = sorted_multiset(right)
	T.assert_equal(#a, #b)
	for index = 1, #a do
		T.assert_equal(a[index], b[index])
	end
end

local function setup_boss_deal_table()
	mock_env.ensure_card_class()
	mock_env.reset_game()
	local game = shell.game()
	game.draw_pile = CardPile(0, 0, game.CARD_W, game.CARD_H, { type = "deck", card_limit = 52 })
	game.dealt_letters = CardPile(0, 0, game.CARD_W * 5, game.CARD_H, {
		type = "hand",
		card_limit = 7,
		selection_limit = 7,
	})
	game.dealt_letters.states = game.dealt_letters.states or {}
	game.dealt_letters.states.visible = true
	game.dealt_letters.refresh_order = game.dealt_letters.refresh_order or function() end
	game.dealt_letters.relayout = game.dealt_letters.relayout or function() end
	game.dealt_letters.snap_drawn = game.dealt_letters.snap_drawn or function() end
	game.dealt_letters.hard_set_cards = game.dealt_letters.hard_set_cards or function() end
	game.pattern_row = {
		apply_screen_position = function() end,
		relayout = function() end,
	}
	local deck = require("word_game.model.cards.deck")
	deck.commit_pile_hosts = deck.commit_pile_hosts or function() end
	return game
end

T.describe("boss hand letters (core)", function()
	T.it("returns empty when word and pattern length differ", function()
		T.assert_equal(#PuzzleSpec.boss_hand_letters("CAT", "CATS"), 0)
	end)

	T.it("extracts exactly the letters hidden by underscores", function()
		local word = "SUNFLOWER"
		local pattern = "_UNFLOW_R"
		local expected = sorted_multiset({ "S", "E" })
		local got = sorted_multiset(PuzzleSpec.boss_hand_letters(word, pattern))
		T.assert_equal(#got, #expected)
		for index = 1, #expected do
			T.assert_equal(got[index], expected[index])
		end
	end)

	T.it("returns one entry per blank even when duplicates are needed", function()
		local word = "BUTTERFLY"
		local pattern = "__TTERF__"
		local letters = PuzzleSpec.boss_hand_letters(word, pattern)
		T.assert_equal(#letters, 4)
		assert_same_multiset(T, letters, { "B", "U", "L", "Y" })
	end)
end)

T.describe("boss stage 1-3 hand clear", function()
	T.it("triggers_boss_word while boss_word_staging is still true", function()
		mock_env.reset_game()
		mock_env.patch_game({
			word_round = {
				set = 1,
				hand_index = 3,
				target = 10,
				jumble = {
					boss_word_staging = true,
					boss_word_active = false,
				},
			},
		})
		local definition = require("word_game.ui.play_effects.definition")
		T.assert_true(definition.triggers_boss_word({ cleared = true }))
	end)

	T.it("does not treat boss hand as boss trigger once boss_word is active", function()
		mock_env.reset_game()
		mock_env.patch_game({
			word_round = {
				set = 1,
				hand_index = 3,
				jumble = {
					boss_word_staging = false,
					boss_word_active = true,
				},
			},
		})
		local definition = require("word_game.ui.play_effects.definition")
		T.assert_false(definition.triggers_boss_word({ cleared = true }))
	end)

	T.it("boss hand clear ends hand-clear focus without token capture", function()
		mock_env.reset_game()
		mock_env.patch_game({
			word_round = {
				set = 1,
				hand_index = 3,
				jumble = { boss_word_active = false },
			},
		})
		local ended = false
		local captured = false
		_G.WORD_GAME_UI = _G.WORD_GAME_UI or {}
		_G.WORD_GAME_UI.HandClearFocus = {
			end_focus = function()
				ended = true
			end,
		}
		_G.WORD_GAME_UI.TokenReward = {
			capture_reward = function()
				captured = true
			end,
		}
		local definition = require("word_game.ui.play_effects.definition")
		definition.capture_token_timer_if_cleared(true, {
			result = { cleared = true },
		})
		T.assert_true(ended)
		T.assert_false(captured)
	end)

	T.it("blocks hand-clear focus while boss intro is staging", function()
		mock_env.reset_game()
		mock_env.patch_game({
			word_round = {
				set = 1,
				hand_index = 3,
				jumble = { boss_word_staging = true },
			},
		})
		local game = shell.game()
		game.ROOM_ATTACH = game.ROOM_ATTACH or {
			T = { x = 0, y = 0, w = 20, h = 11 },
			alignment = { offset = { x = 0, y = 0 } },
		}
		_G.WORD_GAME_UI = _G.WORD_GAME_UI or {}
		_G.WORD_GAME_UI.TokenReward = {
			is_eligible = function()
				return true
			end,
		}
		local focus = require("word_game.ui.tutorial.hand_clear_focus")
		focus.begin()
		T.assert_false(focus.is_active())
	end)
end)

T.describe("boss hand deal and store", function()
	T.it("records boss_cards via JUMBLE_SET_BOSS_CARDS reducer", function()
		core_env.setup_package_path()
		local Store = require("jumbalaya_core.store")
		local cards = {
			{ id = "b1", ability = { letter = "S" } },
			{ id = "b2", ability = { letter = "E" } },
		}
		local store = Store.new({
			word_round = {
				mode = "jumble",
				jumble = {},
			},
		})
		store:dispatch({ type = "JUMBLE_SET_BOSS_CARDS", cards = cards })
		local boss_cards = store:get().word_round.jumble.boss_cards
		T.assert_equal(#boss_cards, 2)
		T.assert_equal(boss_cards[1].ability.letter, "S")
		store:dispatch({ type = "JUMBLE_SET_BOSS_CARDS" })
		T.assert_nil(store:get().word_round.jumble.boss_cards)
	end)

	T.it("instant deal matches boss_hand_letters multiset in store boss_cards", function()
		local game = setup_boss_deal_table()
		mock_env.patch_game({
			word_round = {
				mode = "jumble",
				set = 1,
				hand_index = 3,
				jumble = { boss_word_active = false },
			},
		})
		local word = "GARDENING"
		local pattern = "_AR_E_I_G"
		local letters = PuzzleSpec.boss_hand_letters(word, pattern)
		T.assert_true(#letters > 0)
		local boss_hand = require("word_game.model.cards.deck.boss_hand")
		local game_access = require("word_game.model.game_access")
		local CardLetters = require("jumbalaya_core.dictionary.cards")
		boss_hand.deal_boss_hand(letters, function() end, { instant_deal = true })
		local j = game_access.word_round().jumble
		T.assert_not_nil(j.boss_cards)
		T.assert_equal(#j.boss_cards, #letters)
		T.assert_equal(#(game.dealt_letters.cards or {}), #letters)
		local dealt = {}
		for _, card in ipairs(j.boss_cards) do
			dealt[#dealt + 1] = CardLetters.letter_from_card(card)
		end
		assert_same_multiset(T, dealt, letters)
	end)
end)