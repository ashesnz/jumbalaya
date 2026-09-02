--[[ tests/unit/test_marketplace_timing.lua - Stage progression timing ]]

local T = require("tests.framework")

T.describe("Stage progression timing", function()
	local round = require("word_game.model.round")

	T.it("advances from stage 1-4 to 1-5", function()
		G.GAME = G.GAME or {}
		G.GAME.word_round = { set = 1, hand_index = 4 }
		local result = round.advance_hand()
		T.assert_equal("next", result)
		T.assert_equal(1, G.GAME.word_round.set)
		T.assert_equal(5, G.GAME.word_round.hand_index)
	end)

	T.it("advances from stage 1-9 to 2-1", function()
		G.GAME = G.GAME or {}
		G.GAME.word_round = { set = 1, hand_index = 9 }
		local result = round.advance_hand()
		T.assert_equal("next_set", result)
		T.assert_equal(2, G.GAME.word_round.set)
		T.assert_equal(1, G.GAME.word_round.hand_index)
	end)
end)
