--[[ tests/unit/test_hand_single_draw.lua - Hand deal count and single draw per frame ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local shell = require("jumbalaya-engine.shell")
local piles = require("word_game.model.piles")
local TableAreas = require("word_game.model.table_areas")
local pile_counts = require("jumbalaya_core.cards.pile_counts")
local store_ops = require("word_game.model.store_ops")

local HAND_SIZE = 7

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
	}
end

local function make_hand_card(game, id, letter)
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
		set_card_area = function(self, area)
			self.area = area
		end,
		remove_from_area = function(self)
			self.area = nil
		end,
	}
	setmetatable(card, Card)
	game.letter_inventory = game.letter_inventory or {}
	game.letter_inventory[#game.letter_inventory + 1] = card
	game.LIVE.CARD[#game.LIVE.CARD + 1] = card
	return card
end

local function setup_table_board(hand_cards)
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
	game.dealt_letters.states = game.dealt_letters.states or {}
	game.dealt_letters.states.visible = true
	game.draw_pile.states = game.draw_pile.states or {}
	game.draw_pile.states.visible = true

	local hand_module = require("word_game.ui.cardarea.hand")
	function game.dealt_letters:draw()
		if not self.states.visible then return end
		hand_module.draw_layer(self, "card", function(card)
			card:draw()
		end)
	end
	function game.draw_pile:draw() end

	stub_pattern_row(game)

	for index, letter in ipairs(hand_cards) do
		local card = make_hand_card(game, index, letter)
		game.dealt_letters:emplace(card)
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

	return game, store
end

local function install_draw_counter(hand_cards)
	local counts = {}
	for _, card in ipairs(hand_cards) do
		local base_draw = card.draw
		function card:draw(layer)
			counts[self] = (counts[self] or 0) + 1
			return base_draw(self, layer)
		end
	end
	return counts
end

local function simulate_table_board_frame(game)
	local TableBoard = WORD_GAME_UI.TableBoard
	TableBoard.ensure_store_subscription()

	for _, node in ipairs(game.SCENE_ROOTS or {}) do
		if not node.REMOVED and not node.parent then
			love.graphics.push()
			node:translate_container()
			node:draw()
			love.graphics.pop()
		end
	end

	TableBoard.draw_board(game)
end

local function total_draws(counts, hand_cards)
	local total = 0
	for _, card in ipairs(hand_cards) do
		total = total + (counts[card] or 0)
	end
	return total
end

local function assert_single_draw(counts, hand_cards)
	local total = total_draws(counts, hand_cards)
	T.assert_equal(total, HAND_SIZE, string.format(
		"expected %d hand card draws, got %d",
		HAND_SIZE,
		total
	))
	for index, card in ipairs(hand_cards) do
		T.assert_equal(counts[card] or 0, 1, string.format(
			"hand card %d drawn %d times",
			index,
			counts[card] or 0
		))
	end
end

T.describe("hand single draw", function()
	T.it("deal keeps exactly seven cards in the hand pile", function()
		local game = setup_table_board({ "A", "E", "I", "O", "R", "S", "T" })
		local hand_cards = game.dealt_letters.cards
		T.assert_equal(#hand_cards, HAND_SIZE)
		T.assert_equal(pile_counts.hand_card_count(TableAreas.hand_cards()), HAND_SIZE)
	end)

	T.it("draws each resting hand card once when host and store both hold seven", function()
		local game = setup_table_board({ "A", "E", "I", "O", "R", "S", "T" })
		local hand_cards = game.dealt_letters.cards
		local counts = install_draw_counter(hand_cards)
		simulate_table_board_frame(game)
		assert_single_draw(counts, hand_cards)
	end)

	T.it("draws each hand card once after commit clears the host but store retains seven", function()
		local game, store = setup_table_board({ "C", "A", "T", "S", "E", "R", "N" })
		local hand_cards = {}
		for _, card in ipairs(game.dealt_letters.cards) do
			hand_cards[#hand_cards + 1] = card
		end

		piles.commit_hosts(store, { "hand", "draw" })
		T.assert_equal(#game.dealt_letters.cards, 0)
		T.assert_equal(#store:get().piles.hand, HAND_SIZE)

		local counts = install_draw_counter(hand_cards)
		simulate_table_board_frame(game)
		assert_single_draw(counts, hand_cards)
	end)

	T.it("draws each hand card once when store hand pile is empty but host still holds seven", function()
		local game, store = setup_table_board({ "D", "E", "A", "L", "I", "N", "G" })
		local hand_cards = game.dealt_letters.cards
		store_ops.patch(store, {
			piles = { hand = {}, draw = {}, pattern = {}, bonus = {}, discard = {} },
		})

		local counts = install_draw_counter(hand_cards)
		simulate_table_board_frame(game)
		assert_single_draw(counts, hand_cards)
	end)
end)
