--[[ tests/unit/test_end_run.lua - End Run opens the match-over modal ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local shell = require("jumbalaya-engine.shell")
local Presentation = require("word_game.model.presentation")

T.describe("End Run match overlay", function()
	T.it("opens the match-over modal when End Run is pressed", function()
		mock_env.reset_game()
		local opened
		mock_env.install_presentation({
			EndMatch = {
				open = function(won)
					opened = won
				end,
			},
		})
		local game = shell.game()
		game.STAGE = game.STAGES.RUN
		game.STATE = game.STATES.TABLE_BOARD
		game.SETTINGS = game.SETTINGS or {}
		game.SETTINGS.paused = false

		local Match = require("word_game.model.run.match")
		T.assert_true(Match.end_run({ won = false }))
		T.assert_equal(opened, false)
		T.assert_equal(game.STATE, game.STATES.GAME_OVER)
		T.assert_true(game.SETTINGS.paused)
		T.assert_true(game.STATE_COMPLETE)
	end)

	T.it("ends the run even when discard-bin uses remain", function()
		mock_env.reset_game()
		local opened = false
		mock_env.install_presentation({
			EndMatch = {
				open = function()
					opened = true
				end,
			},
		})
		mock_env.patch_game({
			run_state = { tokens = 0, perks = { { id = "discard_bin" } }, stats = {} },
			discard_bin_count = 0,
		})
		local end_run = require("word_game.ui.perks.discard_bin.end_run")
		T.assert_true(end_run.end_run())
		T.assert_true(opened, "match overlay should open without spending discards")
	end)
end)
