local core_env = require("tests.helpers.core_env")
core_env.setup_package_path()

local T = require("tests.framework")
local Fixtures = require("jumbalaya_core.fixtures")
local Play = require("jumbalaya_core.rules.play")
local JumbleRules = require("jumbalaya_core.rules.jumble")

T.describe("jumbalaya_core play evaluate", function()
	T.it("banks a solved puzzle with no letters placed", function()
		local wr = Fixtures.jumble_word_round({ target = 20 })
		local j = wr.jumble
		j.solved = true
		j.puzzle_points = 5
		j.puzzle_multi = 1.0
		local result = Play.evaluate(j, wr, {
			play_blocked = function() return false end,
			placed_count = function() return 0 end,
			round_target = function() return 20 end,
			run_mode = "time_run",
			on_puzzle_bank = function() end,
			validate_current = function() return nil, "empty" end,
			collect_used_cards = function() return {} end,
		})
		T.assert_equal(result.kind, "bank_puzzle")
		T.assert_equal(result.puzzle_total, 5)
	end)

	T.it("records a valid word play", function()
		local wr = Fixtures.jumble_word_round({ target = 20 })
		local j = wr.jumble
		local recorded = false
		local result = Play.evaluate(j, wr, {
			play_blocked = function() return false end,
			placed_count = function() return 3 end,
			round_target = function() return 20 end,
			run_mode = "time_run",
			validate_current = function() return "CAT" end,
			collect_used_cards = function() return {} end,
			record_puzzle_word = function(word)
				j.puzzle_words = { word }
				j.puzzle_points = 3
				return 0, 3, 1.0, 1.0
			end,
			on_word_recorded = function()
				recorded = true
			end,
		})
		T.assert_equal(result.kind, "word_play")
		T.assert_equal(result.word, "CAT")
		T.assert_true(recorded)
	end)
end)
