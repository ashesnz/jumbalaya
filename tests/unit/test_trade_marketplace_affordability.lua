--[[ tests/unit/test_trade_marketplace_affordability.lua
     Marketplace buttons must disable when the player cannot afford them.
]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

local function stub_market_env()
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
	G.GAME = G.GAME or {}
	G.GAME.run_state = G.GAME.run_state or { tokens = 0, perks = {}, trade_used_this_hand = false }
end

local function walk_trade_buttons(node, out)
	if node.config and node.config.ref_table and node.config.ref_table.action then
		local cfg = node.config
		out[#out + 1] = {
			action = cfg.ref_table.action,
			letter = cfg.ref_table.item and cfg.ref_table.item.letter,
			disabled = cfg.button == nil or cfg.hover == false,
		}
	end
	local children = node.children
	if not children then return end
	if type(children) == "table" then
		for _, child in ipairs(children) do
			walk_trade_buttons(child, out)
		end
		for _, child in pairs(children) do
			if type(child) == "table" and child.config and not child.ui_kind then
				walk_trade_buttons(child, out)
			end
		end
	end
end

local function marketplace_action_buttons(trade_ui)
	local view = LayoutView({
		definition = trade_ui.definition(),
		config = { align = "cm", major = G.ROOM_ATTACH },
	})
	view:recalculate()
	local host = view:find_node_by_id("trade_marketplace_body")
	local body_view = host and host.config and host.config.object
	T.assert_not_nil(body_view, "Marketplace body view should exist")

	local buttons = {}
	if body_view.root_node then
		walk_trade_buttons(body_view.root_node, buttons)
	end
	view:remove()
	local by_action = {}
	for _, btn in ipairs(buttons) do
		if btn.letter == "I" then
			by_action[btn.action] = btn
		end
	end
	return by_action
end

local function bind_offer_with_letter(trade, deck, letter)
	local rolled = trade.roll_offer()
	for _, slot in ipairs(rolled.add.letters) do
		slot.letter = letter
		slot.color = "red"
	end
	stub_market_env()
	local card = deck.create_letter_card(letter, "red")
	card.ability.letter = letter
	G.deck:emplace(card)
	G.playing_cards[1] = card
	trade.sync_offer_cards(rolled)
	return rolled, rolled.add.letters[1]
end

T.describe("Marketplace button affordability (word_game.ui.trade)", function()
	mock_env.reset_game()
	local trade_ui = require("word_game.ui.trade")
	local trade = require("word_game.model.trade")
	local deck = require("word_game.model.cards.deck")

	local function open_market_for(letter, tokens)
		trade_ui.teardown_run()
		G.GAME = G.GAME or {}
		G.GAME.run_state = { tokens = tokens, perks = {}, trade_used_this_hand = false }
		G.RUN = G.RUN or {}
		G.RUN.active = true
		local rolled = bind_offer_with_letter(trade, deck, letter)
		local real_roll = trade.roll_offer
		trade.roll_offer = function() return rolled end
		trade_ui.definition()
		trade.roll_offer = real_roll
		return rolled, rolled.add.letters[1]
	end

	T.it("disables modify when the player cannot afford the modifier cost", function()
		open_market_for("I", 22)
		T.assert_false(trade_ui.can_afford_action("modifier", {}),
			"Sanity: 22 tokens must not afford a 30-token modify")
		local buttons = marketplace_action_buttons(trade_ui)
		T.assert_false(buttons.add.disabled, "Add should stay enabled at 22 tokens")
		T.assert_false(buttons.remove.disabled, "Remove should stay enabled at 22 tokens")
		T.assert_true(buttons.modifier.disabled, "Modify should disable at 22 tokens when it costs 30")
	end)

	T.it("disables add and remove when their costs exceed the balance", function()
		open_market_for("I", 22)
		G.GAME.run_state.tokens = 15
		local buttons = marketplace_action_buttons(trade_ui)
		T.assert_false(buttons.add.disabled, "Add should stay enabled at 15 tokens when it costs 10")
		T.assert_true(buttons.remove.disabled, "Remove should disable at 15 tokens when it costs 20")
		T.assert_true(buttons.modifier.disabled, "Modify should disable at 15 tokens when it costs 30")
	end)

	T.it("refreshes button states after a purchase spends tokens", function()
		local rolled, item = open_market_for("I", 22)
		local ok = trade.apply(item, { action = "remove", cost = trade.ACTION_COSTS.remove, defer_used = true })
		T.assert_true(ok)
		T.assert_equal(G.GAME.run_state.tokens, 2, "Remove should spend 20 tokens")

		local buttons = marketplace_action_buttons(trade_ui)
		T.assert_true(buttons.add.disabled, "Add should disable after spending down to 2 tokens")
		T.assert_true(buttons.remove.disabled, "Remove should disable after spending down to 2 tokens")
		T.assert_true(buttons.modifier.disabled, "Modify should stay disabled after spending down to 2 tokens")
	end)

	T.it("reports affordability through can_afford_action", function()
		G.GAME = G.GAME or {}
		G.GAME.run_state = { tokens = 22, perks = {}, trade_used_this_hand = false }
		G.RUN = G.RUN or {}
		G.RUN.active = true
		local session_state = { add_cost_bonus = 10 }
		T.assert_true(trade_ui.can_afford_action("add", session_state))
		T.assert_true(trade_ui.can_afford_action("remove", session_state))
		T.assert_false(trade_ui.can_afford_action("modifier", session_state))

		G.GAME.run_state.tokens = 2
		T.assert_false(trade_ui.can_afford_action("add", session_state))
		T.assert_false(trade_ui.can_afford_action("remove", session_state))
		T.assert_false(trade_ui.can_afford_action("modifier", session_state))
	end)
end)
