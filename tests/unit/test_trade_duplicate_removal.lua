--[[
	Removing a letter with duplicates in the pack: the marketplace slot
	must refill with another copy of the same letter (3 E's -> remove ->
	2 E's and another E shown in place). Removing the last copy dissolves
	as normal and leaves the slot empty.
]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

local function stub_areas()
	G.playing_cards = {}
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
		G.playing_cards[#G.playing_cards + 1] = card
	end
	return cards
end

local function live_letter_count(letter)
	local n = 0
	for _, card in ipairs(G.playing_cards or {}) do
		if not card.REMOVED and card.ability.letter == letter then
			n = n + 1
		end
	end
	return n
end

local function state_tokens()
	return G.GAME.alpha and G.GAME.alpha.tokens or 0
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

T.describe("Marketplace dissolve slot refill (word_game.ui.trade)", function()
	mock_env.reset_game()
	local trade = require("word_game.model.trade")
	local deck = require("word_game.model.cards.deck")

	-- Populate letter card fronts so make_face_card can build market cards.
	for i = 1, 26 do
		local letter = string.char(string.byte("A") + i - 1)
		for _, color in ipairs({ "red", "black" }) do
			G.P_CARDS[color .. "_" .. letter] = {
				key = color .. "_" .. letter,
				letter = letter,
				color = color,
				pos = { x = 0, y = 0 },
			}
		end
	end

	-- Reload word_game.ui.trade with DissolveFX stubbed out so we can run
	-- the dissolve completion callback synchronously.
	local function load_trade_ui_with_fake_dissolve(captured)
		local real_ui = package.loaded["word_game.ui.trade"]
		local real_fx = package.loaded["app.effects.dissolve_fx"]
		package.loaded["word_game.ui.trade"] = nil
		package.loaded["app.effects.dissolve_fx"] = {
			run = function(target, opts)
				captured.target = target
				captured.opts = opts
			end,
		}
		local ui = require("word_game.ui.trade")
		return ui, function()
			if real_fx ~= nil then
				package.loaded["app.effects.dissolve_fx"] = real_fx
			else
				package.loaded["app.effects.dissolve_fx"] = nil
			end
			if real_ui ~= nil then
				package.loaded["word_game.ui.trade"] = real_ui
			else
				package.loaded["word_game.ui.trade"] = nil
			end
		end
	end

	local function adopt_session(trade_ui, rolled)
		local real_font = alpha_button_font
		alpha_button_font = function()
			return {
				FONT = {
					getWidth = function(_, str) return #(str or "") * 10 end,
					getHeight = function() return 20 end,
				},
				TEXT_HEIGHT_SCALE = 0.7,
				TEXT_OFFSET = { x = 0, y = 0 },
				FONTSCALE = 0.12,
				squish = 1,
			}
		end
		local real_roll = trade.roll_offer
		trade.roll_offer = function() return rolled end
		local ok, err = pcall(trade_ui.definition)
		trade.roll_offer = real_roll
		alpha_button_font = real_font
		if not ok then error(err) end
	end

	local function make_remove_item(card)
		return { mode = "remove", letter = "E", color = "red", card = card }
	end

	local function make_offer(item)
		return {
			add = { mode = "market", letters = {} },
			remove = { mode = "remove", letters = { item } },
			showdown = true,
		}
	end

	local function pick_remove(trade_ui, item)
		trade_ui.on_pick({
			config = { ref_table = { item = item, action = "remove" } },
		})
	end

	local function finish_dissolve(trade_ui, item, captured)
		-- start_remove_dissolve runs before any market card exists for the
		-- fresh UI module, so the dissolve targets the deck card stub.
		local target = item.market_card or item.card or {}
		if captured.opts and captured.opts.on_finish then
			captured.opts.on_finish(target)
		end
	end

	T.it("refills the slot with another copy after the dissolve (3 E's)", function()
		local captured = {}
		local trade_ui, restore = load_trade_ui_with_fake_dissolve(captured)

		local cards = build_deck("E", 3)
		local item = make_remove_item(cards[1])
		G.GAME.alpha = G.GAME.alpha or {}
		G.GAME.alpha.tokens = 1000

		adopt_session(trade_ui, make_offer(item))
		pick_remove(trade_ui, item)

		T.assert_not_nil(captured.opts, "A dissolve should have started")
		T.assert_true(item.removed, "Slot should be flagged removed while dissolving")
		T.assert_equal(live_letter_count("E"), 2, "Deck should already be down to 2 E's")

		finish_dissolve(trade_ui, item, captured)

		T.assert_false(item.removed, "Slot must refill when duplicates remain")
		T.assert_not_nil(item.card, "Item should be bound to a remaining E")
		T.assert_equal(deck.card_letter(item.card), "E", "Refilled slot should show an E")
		restore()
	end)

	T.it("keeps the slot empty after dissolving the last copy", function()
		local captured = {}
		local trade_ui, restore = load_trade_ui_with_fake_dissolve(captured)

		local cards = build_deck("E", 1)
		local item = make_remove_item(cards[1])
		G.GAME.alpha = G.GAME.alpha or {}
		G.GAME.alpha.tokens = 1000

		adopt_session(trade_ui, make_offer(item))
		pick_remove(trade_ui, item)

		T.assert_not_nil(captured.opts, "A dissolve should have started")

		finish_dissolve(trade_ui, item, captured)

		T.assert_true(item.removed, "Last copy: slot stays empty after dissolve")
		T.assert_nil(item.card, "No copy remains to bind")
		T.assert_equal(live_letter_count("E"), 0, "Deck has no E's left")
		restore()
	end)

	T.it("keeps the modal open while a bought card flies when tokens run out", function()
		local captured = {}
		local trade_ui, restore = load_trade_ui_with_fake_dissolve(captured)

		stub_areas()
		local item = { mode = "market", letter = "Z", color = "red" }
		local offer = { add = { mode = "market", letters = { item } }, remove = nil, showdown = false }

		G.GAME.alpha = G.GAME.alpha or {}
		-- Exactly enough for one purchase: after buying, nothing is affordable.
		G.GAME.alpha.tokens = trade.ACTION_COSTS.add

		-- Spy on the run continuation so we can detect the modal closing.
		local calls = {}
		local real_play = WORD_GAME.Play
		WORD_GAME.Play = { continue_after_dealer = function() calls[#calls + 1] = "continue" end }

		adopt_session(trade_ui, offer)
		trade_ui.on_pick({
			config = { ref_table = { item = item, action = "add" } },
		})

		T.assert_true(trade_ui.is_flying(), "Card should be flying after purchase")
		T.assert_equal(#calls, 0, "Modal must stay open until the fly animation lands")

		-- Advance the flyer to landing (FLY_TIME / min dt per draw_pass).
		for _ = 1, 60 do
			trade_ui.draw_pass()
		end

		T.assert_false(trade_ui.is_flying(), "Flyer should have landed")
		T.assert_equal(#calls, 1, "Modal should close (continue run) once the animation completes")

		WORD_GAME.Play = real_play
		restore()
	end)

	T.it("closes after the fly when 36 tokens drop to 6 with nothing affordable", function()
		local captured = {}
		local trade_ui, restore = load_trade_ui_with_fake_dissolve(captured)

		stub_areas()
		-- Escalating add prices: 10, then 20, then 30 across three buys.
		local letters = { "Q", "X", "J" }
		local items = {}
		for _, letter in ipairs(letters) do
			items[#items + 1] = { mode = "market", letter = letter, color = "red" }
		end
		local offer = { add = { mode = "market", letters = items }, remove = nil, showdown = false }

		local calls = {}
		local real_play = WORD_GAME.Play
		WORD_GAME.Play = { continue_after_dealer = function() calls[#calls + 1] = "continue" end }

		G.GAME.alpha = G.GAME.alpha or {}
		G.GAME.alpha.tokens = 66 -- buys at 10 and 20 keep the modal alive

		adopt_session(trade_ui, offer)

		local function land_flyer()
			for _ = 1, 60 do
				trade_ui.draw_pass()
			end
		end

		local function pick(item)
			trade_ui.on_pick({
				config = { ref_table = { item = item, action = "add" } },
			})
		end

		-- Buys 1 and 2 at escalating prices (10, 20).
		pick(items[1])
		land_flyer()
		pick(items[2])
		land_flyer()
		T.assert_equal(#calls, 0, "Modal must stay open while purchases remain affordable")
		T.assert_equal(state_tokens(), 36, "Two buys should leave 36 tokens")

		-- The user's exact scenario: 36 tokens, next add costs 30, leaving
		-- 6 -- below remove (20), modifier (30) and next add (40).
		pick(items[3])

		T.assert_true(trade_ui.is_flying(), "Third card should be flying")
		T.assert_equal(#calls, 0, "Modal must stay open during the animation")

		-- Even if a pending token reward credits the balance mid-flight,
		-- the purchase already drained us: the modal must still close.
		G.GAME.alpha.tokens = 100

		land_flyer()

		T.assert_false(trade_ui.is_flying(), "Flyer should have landed")
		T.assert_equal(#calls, 1, "Modal should close and continue to the next round")

		WORD_GAME.Play = real_play
		restore()
	end)
end)
