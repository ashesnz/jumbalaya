--[[ tests/unit/test_jumble_voucher_discard_refill.lua - Recycle + full hand when hand empties ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local shell = require("jumbalaya-engine.shell")
local store_ops = require("word_game.model.store_ops")
local voucher_discard = require("word_game.model.perks.voucher_discard")

local HAND_SIZE = 7

local function make_letter_card(game, id, letter)
	local card = {
		T = { x = 0, y = 0, w = game.CARD_W, h = game.CARD_H, r = 0, scale = 1 },
		VT = { x = 0, y = 0, w = game.CARD_W, h = game.CARD_H, r = 0, scale = 1 },
		id = id,
		letter_card_id = id,
		ability = { letter = letter },
		states = {
			hover = { is = false, can = true },
			click = { is = false, can = true },
			collide = { is = false, can = true },
			drag = { is = false, can = false },
		},
		facing = "front",
		REMOVED = false,
		parent = nil,
		ARGS = {},
		discard_pos = { x = 0.5, y = 0.5, r = 0 },
		shadow_parallax = { x = 0, y = 0 },
		translate_container = function() end,
		draw = function() end,
		flip = function() end,
		pulse = function() end,
		set_selected = function() end,
		set_card_area = function(self, area)
			self.area = area
		end,
		remove_from_area = function(self)
			self.area = nil
		end,
	}
	setmetatable(card, Card)
	return card
end

local function setup_jumble_deck(hand_letters, draw_letters, recycle_letters)
	mock_env.ensure_card_class()
	mock_env.reset_game()
	local game = shell.game()
	game.TIMELINE = nil
	game.dealt_letters = CardPile(0, 0, 5, 1, { type = "hand", card_limit = HAND_SIZE })
	game.draw_pile = CardPile(0, 0, 1, 1, { type = "deck", card_limit = 52 })
	game.recycle_stash = CardPile(0, 0, 1, 1, { type = "discard", card_limit = 52 })
	game.pattern_row = { area = { cards = {} } }
	game.letter_inventory = {}

	local function track(card)
		game.letter_inventory[#game.letter_inventory + 1] = card
		return card
	end

	for i, letter in ipairs(hand_letters) do
		game.dealt_letters:emplace(track(make_letter_card(game, i, letter)))
	end
	for i, letter in ipairs(draw_letters) do
		game.draw_pile:emplace(track(make_letter_card(game, 100 + i, letter)))
	end
	for i, letter in ipairs(recycle_letters) do
		game.recycle_stash:emplace(track(make_letter_card(game, 200 + i, letter)))
	end

	local store = store_ops.store()
	store_ops.patch(store, {
		word_round = { mode = "jumble", set = 1, hand_index = 1 },
	})
	require("word_game")._bind_engine({ store = store })

	return game, require("word_game.model.cards.deck")
end

T.describe("jumble voucher discard refill", function()
	T.it("stashes voucher discards into recycle for reshuffle", function()
		local game, _ = setup_jumble_deck({ "A" }, {}, {})
		local card = game.dealt_letters.cards[1]
		game.dealt_letters:remove_card(card)
		voucher_discard.stash_discarded_card(card)
		T.assert_equal(#game.recycle_stash.cards, 1)
		T.assert_equal(game.recycle_stash.cards[1], card)
	end)

	T.it("refills a full hand from recycle when the hand is empty and draw is empty", function()
		local game, Deck = setup_jumble_deck({}, {}, { "B", "C", "D", "E", "F", "G", "H", "I" })
		T.assert_equal(Deck.hand_card_count(), 0)
		T.assert_equal(Deck.draw_pile_count(), 0)
		T.assert_true(Deck.needs_jumble_reshuffle())

		local ok = Deck.refill_jumble_hand_when_empty()
		T.assert_true(ok)
		T.assert_equal(Deck.hand_card_count(), HAND_SIZE)
		T.assert_equal(Deck.draw_pile_count(), 1)
	end)
end)
