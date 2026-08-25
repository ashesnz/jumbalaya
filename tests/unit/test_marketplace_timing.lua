--[[ tests/unit/test_marketplace_timing.lua - Marketplace transition timing ]]

local T = require("tests.framework")

T.describe("Marketplace transition timing", function()
	local round_config = require("word_game.config.round_config")

	T.it("does not open the perk marketplace after the 1-3 boss word", function()
		T.assert_false(round_config.is_perk_market_after(1, 2),
			"Clearing 1-2 should not open the perk marketplace")
		T.assert_false(round_config.is_perk_market_after(1, 3),
			"Clearing 1-3 should begin the boss word instead")
	end)

	T.it("does not open the perk marketplace after standard hands", function()
		T.assert_false(round_config.is_perk_market_after(1, 1))
		T.assert_false(round_config.is_perk_market_after(2, 2))
	end)
end)