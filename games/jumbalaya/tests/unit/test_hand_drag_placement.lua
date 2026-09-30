--[[ tests/unit/test_hand_drag_placement.lua - Hand drag selection + pattern row placement ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local shell = require("jumbalaya-engine.shell")
local piles = require("word_game.model.piles")
local pile_selectors = require("jumbalaya_core.store.selectors.piles")
local store_ops = require("word_game.model.store_ops")
local snap = require("word_game.board.placement.snap")
local jumble = require("word_game.model.jumble")
local word_game = require("word_game")
local SceneRoots = require("jumbalaya-engine.scene.roots")

local HAND_SIZE = 7

local function install_ui_facade()
	_G.WORD_GAME_UI = _G.WORD_GAME_UI or {}
	_G.WORD_GAME_UI.TableBoard = require("word_game.ui.table.board")
	_G.WORD_GAME_UI.BonusStackUI = _G.WORD_GAME_UI.BonusStackUI or {
		contains = function() return false end,
	}
	_G.WORD_GAME_UI.Sidebar = _G.WORD_GAME_UI.Sidebar or {}
	_G.WORD_GAME_UI.TableDeck = _G.WORD_GAME_UI.TableDeck or {
		uses_table_draw = function() return false end,
	}
	_G.WORD_GAME_UI.VoucherDiscard = _G.WORD_GAME_UI.VoucherDiscard or {
		try_discard = function() return false end,
	}
	return _G.WORD_GAME_UI
end

local function jumble_word_round()
	return {
		mode = "jumble",
		set = 1,
		hand_index = 1,
		target = 25,
		jumble = {
			puzzle_index = 1,
			solved = false,
			total_score = 0,
			puzzle_points = 0,
			puzzle_multi = 1.0,
			puzzle_words = {},
			slots = {
				{ kind = "fixed", letter = "C" },
				{ kind = "blank", card = nil },
				{ kind = "fixed", letter = "T" },
			},
			puzzle = "C_T",
		},
	}
end

local function prep_drag_card(card)
	card.click_offset = card.click_offset or { x = 0, y = 0 }
	card.container = card.container or { T = { x = 0, y = 0, w = 1, h = 1, r = 0 } }
	card.ARGS = card.ARGS or {}
	card.states = card.states or {}
	card.states.drag = card.states.drag or { can = true, is = false }
	card.states.drag.can = true
end

local function make_letter_card(game, id, letter)
	local card = {
		T = { x = 0, y = 0, w = game.CARD_W, h = game.CARD_H, r = 0, scale = 1 },
		VT = { x = 0, y = 0, w = game.CARD_W, h = game.CARD_H, r = 0, scale = 1 },
		id = id,
		letter_card_id = id,
		ability = { letter = letter, set = "Default" },
		selected = false,
		states = {
			hover = { is = false, can = true },
			click = { is = false, can = true },
			collide = { is = false, can = true },
			drag = { is = false, can = true },
		},
		facing = "front",
		REMOVED = false,
		parent = nil,
		children = {},
		ARGS = {},
		shadow_parallax = { x = 0, y = 0 },
		translate_container = function() end,
		draw = function() end,
		flip = function() end,
		hard_set_T = function() end,
		calculate_parallax = function() end,
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
	prep_drag_card(card)
	return card
end

local function setup_table_board(opts)
	opts = opts or {}
	mock_env.ensure_card_class()
	mock_env.reset_game()
	install_ui_facade()

	local game = shell.game()
	game.TILESCALE = game.TILESCALE or 1
	game.TILESIZE = game.TILESIZE or 20
	game.ARGS = game.ARGS or {}
	game.HIT_ORDER = game.HIT_ORDER or {}
	game.STAGES = game.STAGES or { RUN = 2, MAIN_MENU = 1 }
	game.STATES = game.STATES or { TABLE_BOARD = 4, MENU = 1, SPLASH = 0 }
	game.STAGE = game.STAGES.RUN
	game.STATE = game.STATES.TABLE_BOARD
	game.states = game.states or {}
	game.INPUT = game.INPUT or {
		dragging = { target = nil },
		focused = { target = nil },
		locks = {},
		HID = { touch = false },
	}
	game.INPUT.focused = game.INPUT.focused or { target = nil }
	game.INPUT.dragging = game.INPUT.dragging or { target = nil }
	game.INPUT.cursor_position = game.INPUT.cursor_position or { x = 0, y = 0 }
	game.LIVE = game.LIVE or {}
	game.LIVE.CARD = {}
	game.LIVE.CARDPILE = {}
	game.LIVE.NODE = game.LIVE.NODE or {}
	game.LIVE.TRANSFORM = game.LIVE.TRANSFORM or {}
	game.LIVE.SPRITE = game.LIVE.SPRITE or {}
	game.SCENE_ROOTS = {}
	game.letter_inventory = {}
	game.HAND_CARD_SPACING = game.HAND_CARD_SPACING or 0.78
	game.HIGHLIGHT_H = game.HIGHLIGHT_H or 0.2
	game.MIN_CLICK_DIST = game.MIN_CLICK_DIST or 0.2
	game.TIME_SCALE = game.TIME_SCALE or 1
	game.real_dt = game.real_dt or 0.016

	mock_env.patch_game({
		word_round = opts.word_round or jumble_word_round(),
	})

	game.draw_pile = CardPile(0, 0, game.CARD_W, game.CARD_H, { type = "deck", card_limit = 52 })
	game.dealt_letters = CardPile(0, 0, game.CARD_W * 5, game.CARD_H, {
		type = "hand",
		card_limit = HAND_SIZE,
		selection_limit = 1,
	})
	game.dealt_letters.T.y = 6.5
	game.dealt_letters.states = game.dealt_letters.states or {}
	game.dealt_letters.states.visible = true

	local PlacementTable = require("word_game.board.placement.table")
	game.pattern_row = PlacementTable(game)
	game.pattern_row:create_area(8, 1)
	game.pattern_row:apply_screen_position()

	local store = store_ops.store()
	if store then
		word_game._bind_engine({
			store = store,
			renderer = require("jumbalaya-engine").Renderer.love2d(),
		})
	end

	return game, store
end

local function deal_hand(game, letters)
	local cards = {}
	for index, letter in ipairs(letters) do
		local card = make_letter_card(game, index, letter)
		game.dealt_letters:emplace(card)
		cards[#cards + 1] = card
	end
	local store = store_ops.store()
	if store then
		piles.sync_hosts_to_store(store, { "hand", "draw", "pattern", "bonus", "discard" })
	end
	for _, card in ipairs(cards) do
		card.pile_id = "hand"
	end
	return cards
end

local function assert_only_selected(hand, card)
	T.assert_equal(hand.selected[1], card, "hand selection should match dragged card")
	T.assert_true(card.selected, "dragged card should be selected")
	for _, other in ipairs(hand.selected) do
		T.assert_equal(other, card, "hand should only select one card")
	end
end

local function card_in_pattern_area(area, card)
	for _, entry in ipairs(area.cards or {}) do
		if entry == card then return true end
	end
	return false
end

local function position_card_in_pattern_row(session, card)
	local area = session.area
	card.T.w = card.T.w or session.game.CARD_W
	card.T.h = card.T.h or session.game.CARD_H
	card.T.x = area.T.x + area.T.w * 0.5 - card.T.w / 2
	card.T.y = area.T.y + area.T.h / 2 - card.T.h / 2
	card.VT.x, card.VT.y, card.VT.w, card.VT.h = card.T.x, card.T.y, card.T.w, card.T.h
end

T.describe("hand drag selection", function()
	T.it("selects the dragged card when another hand card was already selected", function()
		local game = setup_table_board()
		local cards = deal_hand(game, { "A", "E", "I" })
		local hand = game.dealt_letters

		hand:add_selection(cards[1], true)
		T.assert_equal(hand.selected[1], cards[1])

		cards[3]:drag()
		assert_only_selected(hand, cards[3])
		T.assert_false(cards[1].selected, "previous selection should clear")
	end)

	T.it("selects the dragged card after commit clears host area but store retains hand pile", function()
		local game, store = setup_table_board()
		local cards = deal_hand(game, { "C", "A", "T" })
		local hand = game.dealt_letters

		hand:add_selection(cards[1], true)
		piles.commit_hosts(store, { "hand", "draw" })

		T.assert_equal(#hand.cards, 0)
		T.assert_nil(cards[2].area)
		T.assert_equal(#store:get().piles.hand, 3)

		cards[2]:drag()
		assert_only_selected(hand, cards[2])
		T.assert_false(cards[1].selected, "stale highlight should clear on drag")
	end)

	T.it("clears pile selection when resting cards are released during commit", function()
		local game, store = setup_table_board()
		local cards = deal_hand(game, { "D", "O", "G" })
		local hand = game.dealt_letters

		hand:add_selection(cards[2], true)
		piles.commit_hosts(store, { "hand" })

		T.assert_equal(#hand.selected, 0, "commit should drop detached cards from hand.selected")
		T.assert_false(cards[2].selected, "released card should not stay selected")
	end)
end)

T.describe("pattern row placement", function()
	T.it("places a hand card into the pattern area and jumble blank slot", function()
		local game, store = setup_table_board()
		local cards = deal_hand(game, { "A", "E", "I", "O", "R", "S", "T" })
		local card = cards[1]
		local session = game.pattern_row

		position_card_in_pattern_row(session, card)
		local effects = snap.try_snap(session, card)

		T.assert_true(jumble.is_active())
		T.assert_equal(jumble.state().slots[2].card, card, "blank slot should hold placed card")
		T.assert_equal(card.area, session.area, "card area should be the pattern row")
		T.assert_true(card_in_pattern_area(session.area, card), "pattern host should list placed card")

		local pattern = pile_selectors.pattern_cards(store:get())
		T.assert_not_nil(pattern[2], "store pattern pile should record placed card")
		T.assert_equal(pattern[2].id, card.id)
		T.assert_equal(card.pile_id, "pattern")
		T.assert_true(effects.hand_shuffle_sync, "placement should request hand shuffle sync")
	end)

	T.it("keeps live pattern rendering after the store pattern pile is populated", function()
		local game, store = setup_table_board()
		local cards = deal_hand(game, { "A", "B", "C", "D", "E", "F", "G" })
		local session = game.pattern_row
		local card = cards[4]

		position_card_in_pattern_row(session, card)
		snap.try_snap(session, card)

		local TableBoardView = require("word_game.ui.views.table_board_view")
		local view = TableBoardView.new({ store = store })
		view:bind_store(store)
		T.assert_false(
			view:should_render_pattern_from_store(),
			"pattern row must not switch to flat store pile view"
		)
		T.assert_true(card_in_pattern_area(session.area, card), "placed card stays on pattern host")
	end)
end)

T.describe("jumble row letter packing", function()
	T.it("packs play-row letters flush and grows the word instead of leaving a gutter", function()
		mock_env.reset_game()
		local game = shell.game()
		game.CARD_W = 2
		game.HAND_CARD_SPACING = 0.78
		local geo = require("word_game.board.jumble.geometry")
		T.assert_equal(geo.span_slot_spacing(), 1)
		T.assert_equal(geo.group_width(2, 1, geo.span_slot_spacing()), 2)
		T.assert_equal(geo.group_width(2, 2, geo.span_slot_spacing()), 4)
		T.assert_equal(geo.group_width(2, 3, geo.span_slot_spacing()), 6)
		local config = require("word_game.board.placement.config")
		T.assert_equal(config.row_width_for_slots(7), 7.6)
		local ctx = {
			card_w = function() return 2 end,
			card_h = function() return 2.75 end,
			card_limit = function() return 7 end,
		}
		T.assert_equal(geo.area_width(ctx), 2 * config.row_width_for_slots(7))
	end)

	T.it("packs C_T as three flush tiles inside the seven-card tray, then four for CENT", function()
		mock_env.reset_game()
		local geo = require("word_game.board.jumble.geometry")
		local session = {
			area = { T = { x = 0, y = 0, w = 20, h = 3 }, cards = {} },
			ctx = {
				card_w = function() return 2 end,
				card_h = function() return 2.75 end,
			},
		}
		local three = geo.span_centers(session, 3)
		T.assert_equal(#three, 3)
		T.assert_equal(three[3] - three[1], 4, "C to T is two card-widths, not the full tray")
		T.assert_equal((three[1] + three[3]) / 2, 10, "three-letter word stays centered")
		local four = geo.span_centers(session, 4)
		T.assert_equal(#four, 4)
		T.assert_equal(four[4] - four[1], 6, "CENT is three card-widths from C to T")
		T.assert_equal((four[1] + four[4]) / 2, 10, "four-letter word stays centered")
	end)

	T.it("packs E flush on C _ T after a scored word, even if span.cards was cleared", function()
		local Topology = require("jumbalaya_core.jumble.slot_topology")
		local PuzzleSpec = require("jumbalaya_core.jumble.puzzle_spec")
		local Slots = require("jumbalaya_core.jumble.slots")
		local geo = require("word_game.board.jumble.geometry")
		local puzzle = PuzzleSpec.resolve_puzzle({ span = { "C", "T" }, min = 3, max = 7 })
		local slots = Slots.parse_slots(puzzle)
		local e = { ability = { letter = "E" }, T = { w = 2, h = 2.75 } }
		local j = { puzzle = puzzle, slots = slots, puzzle_words = { "CAT" } }
		j.slots[2].cards = { { ability = { letter = "A" } } }
		local session = {
			area = { T = { x = 0, y = 0, w = 20, h = 3 }, cards = { e } },
			ctx = {
				card_w = function() return 2 end,
				card_h = function() return 2.75 end,
			},
		}
		local cells = Topology.span_cells(j, session.area.cards)
		T.assert_equal(#cells, 3)
		T.assert_equal(cells[2].card, e)
		local three = geo.span_centers(session, #cells)
		T.assert_equal(three[3] - three[1], 4)
	end)

	T.it("draws empty C _ T gaps as underlines instead of placeholder tiles", function()
		mock_env.reset_game()
		local PuzzleSpec = require("jumbalaya_core.jumble.puzzle_spec")
		local Slots = require("jumbalaya_core.jumble.slots")
		local puzzle = PuzzleSpec.resolve_puzzle({ span = { "C", "T" }, min = 3, max = 7 })
		mock_env.publish_game({
			word_round = {
				mode = "jumble",
				jumble = {
					puzzle = puzzle,
					slots = Slots.parse_slots(puzzle),
				},
			},
		})
		T.assert_not_nil(jumble.state() and jumble.state().slots)
		local tiles, underlines = 0, 0
		local orig_rect = love.graphics.rectangle
		local orig_poly = love.graphics.polygon
		local orig_line = love.graphics.line
		love.graphics.rectangle = function(mode)
			if mode == "fill" then tiles = tiles + 1 end
		end
		love.graphics.polygon = function(mode)
			if mode == "fill" then tiles = tiles + 1 end
		end
		love.graphics.line = function()
			underlines = underlines + 1
		end
		require("word_game.ui.table.jumble_fixed_letters").draw({
			jumble_geometry = require("word_game.board.jumble.geometry"),
			area = { T = { x = 0, y = 0, w = 20, h = 3 }, cards = {} },
			ctx = {
				card_w = function() return 2 end,
				card_h = function() return 2.75 end,
				tile_scale = function() return 20 end,
			},
		})
		love.graphics.rectangle = orig_rect
		love.graphics.polygon = orig_poly
		love.graphics.line = orig_line
		T.assert_equal(tiles, 2, "only the two fixed letters should be tiles")
		T.assert_equal(underlines, 1, "the empty gap should be an underline")
	end)
end)
