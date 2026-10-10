--[[ tests/unit/test_hand_refill.lua - Top up dealt hand from the draw pile after play ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local shell = require("jumbalaya-engine.shell")
local piles = require("word_game.model.piles")
local TableAreas = require("word_game.model.table_areas")
local store_ops = require("word_game.model.store_ops")
local SceneRoots = require("jumbalaya-engine.scene.roots")

local HAND_SIZE = 7
local START_DRAW = 5

local function install_ui_facade()
	if not _G.Game then
		require("app.bootstrap.kind_globals").install_game()
	end
	_G.WORD_GAME_UI = _G.WORD_GAME_UI or {}
	_G.WORD_GAME_UI.TableBoard = require("word_game.ui.table.board")
	_G.WORD_GAME_UI.BonusStackUI = _G.WORD_GAME_UI.BonusStackUI or {
		contains = function() return false end,
	}
	_G.WORD_GAME_UI.Sidebar = _G.WORD_GAME_UI.Sidebar or {}
	_G.WORD_GAME_UI.TableDeck = _G.WORD_GAME_UI.TableDeck or {
		uses_table_draw = function() return false end,
	}
	return _G.WORD_GAME_UI
end

local function stub_pattern_row(game)
	game.pattern_row = {
		area = {
			T = { x = 0, y = 0, w = 8, h = 1 },
			translate_container = function() end,
			cards = {},
		},
		draw_run_pass = function() end,
		update = function() end,
		on_remove_card = function() end,
	}
end

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
		shadow_parallax = { x = 0, y = 0 },
		translate_container = function() end,
		draw = function() end,
		flip = function() end,
		pulse = function() end,
		set_card_area = function(self, area)
			self.area = area
			SceneRoots.set_parent(self, area)
		end,
		remove_from_area = function(self)
			self.area = nil
			SceneRoots.set_parent(self, nil)
			SceneRoots.unregister(self)
		end,
	}
	setmetatable(card, Card)
	card._live_registry = "transform"
	SceneRoots.register(card, "transform")
	game.letter_inventory = game.letter_inventory or {}
	game.letter_inventory[#game.letter_inventory + 1] = card
	game.LIVE.CARD[#game.LIVE.CARD + 1] = card
	return card
end

local function run_scheduled_tweens(game)
	function game.TIMELINE.enqueue(_self, tween)
		if type(tween) == "table" and type(tween.func) == "function" then
			tween.func()
		end
	end
end

local function setup_hand_and_draw(hand_letters, draw_letters)
	mock_env.ensure_card_class()
	mock_env.reset_game()
	install_ui_facade()

	local game = shell.game()
	game.TILESCALE = game.TILESCALE or 1
	game.TILESIZE = game.TILESIZE or 20
	game.ARGS = game.ARGS or {}
	game.HIT_ORDER = game.HIT_ORDER or {}
	game.STAGES = game.STAGES or { RUN = 2, MAIN_MENU = 1 }
	game.STAGE = game.STAGES.RUN
	game.STATE = game.STATES.TABLE_BOARD
	game.states = game.states or {}
	game.INPUT = {
		dragging = { target = nil },
		focused = { target = nil },
		locks = {},
	}
	game.LIVE = game.LIVE or {}
	game.LIVE.CARD = game.LIVE.CARD or {}
	game.LIVE.CARDPILE = game.LIVE.CARDPILE or {}
	game.LIVE.NODE = game.LIVE.NODE or {}
	game.LIVE.TRANSFORM = game.LIVE.TRANSFORM or {}
	game.LIVE.SPRITE = game.LIVE.SPRITE or {}
	game.LIVE.POPUP = game.LIVE.POPUP or {}
	game.LIVE.ALERT = game.LIVE.ALERT or {}
	game.SCENE_ROOTS = game.SCENE_ROOTS or {}
	game.letter_inventory = {}

	game.draw_pile = CardPile(0, 0, game.CARD_W, game.CARD_H, { type = "deck", card_limit = 52 })
	game.dealt_letters = CardPile(0, 0, game.CARD_W * 5, game.CARD_H, {
		type = "hand",
		card_limit = HAND_SIZE,
		selection_limit = HAND_SIZE,
	})
	game.recycle_stash = CardPile(0, 0, game.CARD_W, game.CARD_H, { type = "discard", card_limit = 52 })
	game.dealt_letters.states = game.dealt_letters.states or {}
	game.dealt_letters.states.visible = true
	game.draw_pile.states = game.draw_pile.states or {}
	game.draw_pile.states.visible = true

	stub_pattern_row(game)
	run_scheduled_tweens(game)

	for index, letter in ipairs(hand_letters) do
		game.dealt_letters:add_card(make_letter_card(game, index, letter))
	end
	for index, letter in ipairs(draw_letters) do
		game.draw_pile:add_card(make_letter_card(game, 100 + index, letter))
	end

	local store = store_ops.store()
	if store then
		piles.sync_hosts_to_store(store, { "hand", "draw", "pattern", "bonus", "discard" })
	end

	local word_game = require("word_game")
	local Engine = require("jumbalaya-engine")
	word_game._bind_engine({
		store = store,
		renderer = Engine.Renderer.love2d(),
	})

	return game, store, require("word_game.model.cards.deck")
end

local function play_from_hand(game, count)
	for _ = 1, count do
		local card = game.dealt_letters.cards[#game.dealt_letters.cards]
		game.dealt_letters:remove_card(card)
	end
end

T.describe("hand refill from draw pile", function()
	T.it("does not count an empty live pattern as held when the store pile is stale", function()
		local game, store, Deck = setup_hand_and_draw(
			{ "A", "E", "I", "O", "R", "S", "T" },
			{ "B", "C", "D", "F", "G" }
		)
		play_from_hand(game, 1)
		store_ops.patch(store, {
			piles = {
				pattern = {
					{ id = 7, ability = { letter = "T" }, pile_id = "pattern" },
				},
			},
		})
		T.assert_equal(#game.pattern_row.area.cards, 0)
		T.assert_equal(#TableAreas.pattern_cards(), 0)
		T.assert_equal(Deck.held_count(), HAND_SIZE - 1)
		T.assert_equal(Deck.draw_pile_count(), START_DRAW)
	end)

	T.it("deals one card after playing one and leaves four in the deck", function()
		local game, store, Deck = setup_hand_and_draw(
			{ "A", "E", "I", "O", "R", "S", "T" },
			{ "B", "C", "D", "F", "G" }
		)
		play_from_hand(game, 1)
		store_ops.patch(store, {
			piles = {
				pattern = {
					{ id = 7, ability = { letter = "T" }, pile_id = "pattern" },
				},
			},
		})

		local dealt = Deck.deal_into_hand(HAND_SIZE)
		T.assert_equal(dealt, 1)
		T.assert_equal(#store:get().piles.hand, HAND_SIZE)
		T.assert_equal(#store:get().piles.draw, START_DRAW - 1)
		T.assert_equal(Deck.cards_left(), START_DRAW - 1)
	end)

	T.it("deals two cards after playing two and leaves three in the deck", function()
		local game, store, Deck = setup_hand_and_draw(
			{ "A", "E", "I", "O", "R", "S", "T" },
			{ "B", "C", "D", "F", "G" }
		)
		play_from_hand(game, 2)

		local dealt = Deck.deal_into_hand(HAND_SIZE)
		T.assert_equal(dealt, 2)
		T.assert_equal(#store:get().piles.hand, HAND_SIZE)
		T.assert_equal(#store:get().piles.draw, START_DRAW - 2)
		T.assert_equal(Deck.cards_left(), START_DRAW - 2)
	end)

	T.it("draws nothing when the deck is empty and keeps remaining hand cards", function()
		local game, store, Deck = setup_hand_and_draw(
			{ "A", "E", "I", "O", "R" },
			{}
		)

		local dealt = Deck.deal_into_hand(HAND_SIZE)
		T.assert_equal(dealt, 0)
		T.assert_equal(#store:get().piles.hand, 5)
		T.assert_equal(#store:get().piles.draw, 0)
		T.assert_equal(Deck.cards_left(), 0)
		T.assert_equal(#game.dealt_letters.cards, 0)
		T.assert_equal(Deck.held_count(), 5)
	end)
end)
