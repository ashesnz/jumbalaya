--[[ tests/unit/test_voucher_tokens.lua - Perk marketplace token costs ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("Perk token costs", function()
	T.it("uses 2 points for stage 1-1", function()
		local round_config = require("word_game.config.round_config")
		T.assert_equal(round_config.hand_target(1, 1), 2)
	end)
	T.it("uses the configured 10 token cost for every offer", function()
		mock_env.reset_game()
		local perk = require("word_game.model.perk")
		local offer = perk.roll_offer(3)
		T.assert_equal(#offer, 3)
		for i, entry in ipairs(offer) do
			local cost = entry.token_cost
			T.assert_not_nil(cost, "Offer " .. i .. " should have a token cost")
			T.assert_equal(cost, 10, "Every perk should cost 10 tokens")
		end
	end)

	T.it("blocks purchase when the player cannot afford a perk", function()
		mock_env.reset_game()
		local perk = require("word_game.model.perk")
		local state = require("word_game.model.state")
		local entry = {
			id = "extra_redraw",
			name = "Extra Redraw",
			desc = "+1 redraw this showdown.",
			pos = { x = 6, y = 0 },
			token_cost = 40,
		}
		state.add_tokens(30)
		T.assert_false(perk.can_afford(entry))
		local ok, err = perk.purchase(entry)
		T.assert_false(ok)
		T.assert_equal(err, "Not enough tokens")
		T.assert_equal(state.tokens(), 30)
	end)

	T.it("deducts tokens when a perk is purchased", function()
		mock_env.reset_game()
		local perk = require("word_game.model.perk")
		local state = require("word_game.model.state")
		local entry = {
			id = "extra_redraw",
			name = "Extra Redraw",
			desc = "+1 redraw this showdown.",
			pos = { x = 6, y = 0 },
			token_cost = 40,
		}
		state.add_tokens(50)
		local ok = perk.purchase(entry)
		T.assert_true(ok)
		T.assert_equal(state.tokens(), 10)
		T.assert_equal(G.GAME.selected_perk.id, "extra_redraw")
	end)
end)
