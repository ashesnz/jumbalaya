--[[ tests/unit/test_marketplace_timing.lua - Stage progression and marketplace timing ]]

local T = require("tests.framework")

T.describe("Marketplace transition timing", function()
	local round_config = require("word_game.config.round_config")
	local round = require("word_game.model.round")

	T.it("does not open the perk marketplace after showdown hands", function()
		T.assert_false(round_config.is_perk_market_after(1, 2))
		T.assert_false(round_config.is_perk_market_after(1, 3))
		T.assert_false(round_config.is_perk_market_after(1, 1))
		T.assert_false(round_config.is_perk_market_after(2, 2))
	end)

	T.it("advances from stage 1-4 to 2-1", function()
		G.GAME = G.GAME or {}
		G.GAME.word_round = { set = 1, hand_index = 4 }
		local result = round.advance_hand()
		T.assert_equal("next_set", result)
		T.assert_equal(2, G.GAME.word_round.set)
		T.assert_equal(1, G.GAME.word_round.hand_index)
	end)
end)
