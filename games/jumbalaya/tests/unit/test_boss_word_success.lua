--[[ tests/unit/test_boss_word_success.lua - Boss word solve routes to gutter animation ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("boss word success choreography", function()
	T.it("present_word_play_after_cards calls boss_success when boss_word is active", function()
		mock_env.reset_game()
		local word_play = require("word_game.ui.play_effects.animate.word_play")
		local boss_success = require("word_game.ui.play_effects.animate.boss_success")
		local called = false
		local orig = boss_success.present_boss_word_success
		boss_success.present_boss_word_success = function()
			called = true
		end

		mock_env.patch_game({
			word_round = {
				set = 1,
				hand_index = 3,
				target = 2,
				jumble = {
					boss_word_active = true,
					total_score = 2,
					puzzle = {
						kind = "rigid",
						pattern = "_AR_E_I_G",
						boss_word = "GARDENING",
						display = "_AR_E_I_G",
					},
				},
			},
		})

		local jumble = require("word_game.model.jumble")
		word_play.present_word_play_after_cards(jumble, jumble.state(), {
			kind = "word_play",
			word = "GARDENING",
			cleared = true,
			used_cards = {},
			new_score = 11,
			new_pts = 9,
			word_pts = 9,
		}, nil, nil)

		boss_success.present_boss_word_success = orig
		T.assert_true(called, "boss word play should trigger gutter fly-off choreography")
	end)

	T.it("routes on result.boss_word_cleared even when boss_word_active is false", function()
		mock_env.reset_game()
		local word_play = require("word_game.ui.play_effects.animate.word_play")
		local boss_success = require("word_game.ui.play_effects.animate.boss_success")
		local called = false
		local orig = boss_success.present_boss_word_success
		boss_success.present_boss_word_success = function()
			called = true
		end

		mock_env.patch_game({
			word_round = {
				set = 1,
				hand_index = 3,
				target = 2,
				jumble = {
					boss_word_active = false,
					total_score = 2,
					puzzle = {
						kind = "rigid",
						pattern = "_AR_E_I_G",
						boss_word = "GARDENING",
						display = "_AR_E_I_G",
					},
				},
			},
		})

		local jumble = require("word_game.model.jumble")
		word_play.present_word_play_after_cards(jumble, jumble.state(), {
			kind = "word_play",
			word = "GARDENING",
			boss_word_cleared = true,
			cleared = false,
			used_cards = {},
			new_score = 11,
			new_pts = 9,
			word_pts = 9,
		}, nil, nil)

		boss_success.present_boss_word_success = orig
		T.assert_true(called, "boss_word_cleared from evaluate should drive gutter choreography")
	end)

	T.it("should_route_boss_gutter when boss_cards are dealt", function()
		mock_env.reset_game()
		local definition = require("word_game.ui.play_effects.definition")
		local jumble = require("word_game.model.jumble")
		mock_env.patch_game({
			word_round = {
				set = 1,
				hand_index = 3,
				jumble = {
					boss_word_active = false,
					boss_cards = { { ability = { letter = "A" } } },
					puzzle = { kind = "rigid", boss_word = "CAT", pattern = "_AT" },
				},
			},
		})
		T.assert_true(definition.should_route_boss_gutter(jumble, {
			kind = "word_play",
			word = "CAT",
		}))
	end)

	T.it("routes when boss_word_active even if boss_word_cleared flag is missing", function()
		mock_env.reset_game()
		local word_play = require("word_game.ui.play_effects.animate.word_play")
		local boss_success = require("word_game.ui.play_effects.animate.boss_success")
		local called = false
		local orig = boss_success.present_boss_word_success
		boss_success.present_boss_word_success = function()
			called = true
		end

		mock_env.patch_game({
			word_round = {
				set = 1,
				hand_index = 3,
				target = 2,
				jumble = {
					boss_word_active = true,
					total_score = 2,
					puzzle = {
						kind = "rigid",
						boss_word = "GARDENING",
						pattern = "_AR_E_I_G",
					},
				},
			},
		})

		local jumble = require("word_game.model.jumble")
		word_play.present_word_play_after_cards(jumble, jumble.state(), {
			kind = "word_play",
			word = "GARDENING",
			cleared = false,
			used_cards = {},
		}, function() end, nil)

		boss_success.present_boss_word_success = orig
		T.assert_true(called, "boss_word_active should force boss gutter routing")
	end)

	T.it("does not treat pre-boss stage clear as boss_success", function()
		mock_env.reset_game()
		local word_play = require("word_game.ui.play_effects.animate.word_play")
		local boss_success = require("word_game.ui.play_effects.animate.boss_success")
		local called = false
		local orig = boss_success.present_boss_word_success
		boss_success.present_boss_word_success = function()
			called = true
		end

		mock_env.patch_game({
			word_round = {
				set = 1,
				hand_index = 3,
				target = 2,
				jumble = {
					boss_word_active = false,
					boss_word_staging = true,
					total_score = 2,
					puzzle = { span = { "C", "T" }, min = 3, max = 7, kind = "span" },
				},
			},
		})

		local jumble = require("word_game.model.jumble")
		word_play.present_word_play_after_cards(jumble, jumble.state(), {
			kind = "word_play",
			word = "CAT",
			cleared = true,
			used_cards = {},
			new_score = 2,
		}, function() end, nil)

		boss_success.present_boss_word_success = orig
		T.assert_false(called, "stage clear into boss intro should not run boss_success")
	end)
end)