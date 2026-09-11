--[[ tests/unit/test_marketplace_purchase_deal.lua - Marketplace purchase integration ]]

local T = require("tests.framework")
local classic = require("tests.helpers.classic_stage_advance")

local function deck_find(letter)
	for _, card in ipairs(G.letter_inventory or {}) do
		if card.ability and card.ability.letter == letter and not card.REMOVED then
			return card
		end
	end
	return nil
end

T.describe("Marketplace purchase then deal", function()
	T.it("adds a purchased letter to the deck through trade.apply", function()
		local ctx = classic.begin({ deal = false })
		local trade = ctx.trade
		local starter = ctx.starter

		local offer = trade.roll_offer()
		local item = offer.add.letters[1]
		local ok, err = trade.apply(item, { action = "add", cost = 10, defer_used = true })
		T.assert_true(ok, err or "purchase should succeed")
		T.assert_not_nil(deck_find(item.letter), "Purchased letter should exist in the deck")
		T.assert_equal(#G.letter_inventory, starter + 1, "Deck should grow by one purchased card")

		ctx.restore()
	end)
end)
