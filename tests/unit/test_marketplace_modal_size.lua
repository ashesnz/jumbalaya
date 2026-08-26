--[[
	Regression: removing a marketplace card must never change the modal
	body dimensions (the card face and modifier chip are replaced by
	placeholders that reserve the exact same footprint).
]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("Marketplace modal size stability on card removal", function()
	mock_env.reset_game()

	T.it("keeps the modal body width and height identical after a remove", function()
		local trade = require("word_game.model.trade")
		local trade_ui = require("word_game.ui.trade")
		local deck = require("word_game.model.cards.deck")

		-- Wide font stub: forces the modifier chip to be text-width-bound
		-- (the worst case for layout shifts when the text disappears).
		local real_button_font = alpha_button_font
		alpha_button_font = function()
			return {
				FONT = {
					getWidth = function(_, str) return #(str or "") * 200 end,
					getHeight = function() return 100 end,
				},
				TEXT_HEIGHT_SCALE = 0.7,
				TEXT_OFFSET = { x = 0, y = 0 },
				FONTSCALE = 0.12,
				squish = 1,
			}
		end

		local rolled = trade.roll_offer()
		local item = rolled.add.letters[1]
		G.playing_cards = {}
		G.deck = {
			cards = {},
			config = {},
			emplace = function(self, card) table.insert(self.cards, card) end,
			remove_card = function(self) return table.remove(self.cards) end,
			shuffle = function() end,
			hard_set_T = function() end,
		}
		G.hand = {
			cards = {}, config = {},
			emplace = function() end, set_ranks = function() end,
			relayout = function() end, snap_VT = function() end,
			hard_set_cards = function() end,
		}
		local card = deck.create_letter_card(item.letter, "red")
		card.ability.letter = item.letter
		G.deck:emplace(card)
		G.playing_cards[1] = card
		trade.sync_offer_cards(rolled)

		-- Make the marketplace session adopt OUR offer so we hold the items.
		local real_roll = trade.roll_offer
		trade.roll_offer = function() return rolled end
		trade_ui.definition()
		trade.roll_offer = real_roll
		G.GAME.alpha = G.GAME.alpha or {}
		G.GAME.alpha.tokens = 500

		local function body_dimensions()
			local view = LayoutView({
				definition = trade_ui.definition(),
				config = { align = "cm" },
			})
			view:recalculate()
			local host = view:find_node_by_id("trade_marketplace_body")
			local w, h = host and host.VT.w or -1, host and host.VT.h or -1
			view:remove()
			return w, h
		end

		local w1, h1 = body_dimensions()

		-- Simulate the remove: the deck copy is gone and the item is flagged
		-- exactly like start_remove_dissolve does.
		item.removed = true
		item.card = nil

		local w2, h2 = body_dimensions()

		alpha_button_font = real_button_font

		T.assert_true(w1 > 0 and h1 > 0, "Body should have measurable dimensions")
		T.assert_equal(w2, w1, "Modal body width must not change when a card is removed")
		T.assert_equal(h2, h1, "Modal body height must not change when a card is removed")
	end)
end)
