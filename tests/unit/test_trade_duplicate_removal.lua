--[[
	Removing a letter with duplicates in the pack: the marketplace slot
	must refill with another copy of the same letter (3 E's -> remove ->
	2 E's and another E shown in place). Removing the last copy dissolves
	as normal and leaves the slot empty.
]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

local function stub_areas()
	G.letter_inventory = {}
	G.deck = {
		cards = {},
		config = {},
		T = { x = 0, y = 0 },
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
	G.discard = {
		cards = {}, config = {},
		emplace = function() end, remove_card = function() end,
	}
end

--- Build a deck of `copies` identical letter cards.
local function build_deck(letter, copies)
	stub_areas()
	local cards = {}
	for _ = 1, copies do
		local card = {
			ability = { letter = letter, letter_color = "red" },
			REMOVED = false,
		}
		cards[#cards + 1] = card
		G.deck:emplace(card)
		G.letter_inventory[#G.letter_inventory + 1] = card
	end
	return cards
end

local function live_letter_count(letter)
	local n = 0
	for _, card in ipairs(G.letter_inventory or {}) do
		if not card.REMOVED and card.ability.letter == letter then
			n = n + 1
		end
	end
	return n
end

local function state_tokens()
	return G.GAME.run_state and G.GAME.run_state.tokens or 0
end

T.describe("Marketplace duplicate removal (word_game.model.trade)", function()
	mock_env.reset_game()
	local trade = require("word_game.model.trade")
	local deck = require("word_game.model.cards.deck")

	T.it("rebinds the offer to another copy when duplicates remain (3 E's)", function()
		local cards = build_deck("E", 3)
		local item = { mode = "remove", letter = "E", color = "red", card = cards[1] }

		local ok = trade.apply(item, { action = "remove", cost = 0, defer_used = true })
		T.assert_true(ok, "Removing one of three E's should succeed")
		T.assert_equal(live_letter_count("E"), 2, "Deck should drop from 3 to 2 E's")
		T.assert_nil(item.card, "The removed copy should unbind immediately")

		trade.sync_offer_cards({ remove = { mode = "remove", letters = { item } } })

		T.assert_not_nil(item.card, "The offer should rebind to a remaining copy")
		T.assert_false(item.card.REMOVED, "The rebound copy must be a live card")
		T.assert_equal(deck.card_letter(item.card), "E", "The rebound copy should be an E")
		T.assert_not_equal(item.card, cards[1], "The rebound copy must not be the destroyed card")
	end)

	T.it("leaves nothing to bind when removing the last copy", function()
		local cards = build_deck("E", 1)
		local item = { mode = "remove", letter = "E", color = "red", card = cards[1] }

		local ok = trade.apply(item, { action = "remove", cost = 0, defer_used = true })
		T.assert_true(ok, "Removing the last E should succeed")
		T.assert_equal(live_letter_count("E"), 0, "Deck should have no E's left")

		trade.sync_offer_cards({ remove = { mode = "remove", letters = { item } } })

		T.assert_nil(item.card, "No copy remains so the offer must stay unbound")
		T.assert_nil(deck.find_deck_card("E"), "find_deck_card should find no E")
	end)
end)
