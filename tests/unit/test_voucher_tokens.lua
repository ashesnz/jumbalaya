--[[ tests/unit/test_voucher_tokens.lua - Perk stamp rolls and selection ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("Perk stamp rewards", function()
	T.it("rolls a perk from the configured pool", function()
		mock_env.reset_game()
		local perk = require("word_game.model.perk")
		local rolled = perk.roll_stamp_perk()
		T.assert_not_nil(rolled)
		T.assert_not_nil(rolled.id)
		T.assert_not_nil(rolled.name)
	end)

	T.it("stores the selected perk on the run", function()
		mock_env.reset_game()
		local perk = require("word_game.model.perk")
		local rolled = perk.roll_stamp_perk()
		T.assert_true(perk.apply_choice(rolled))
		T.assert_equal(G.GAME.selected_perk.id, rolled.id)
	end)
end)
