--[[ tests/unit/test_table_board_boot.lua - TABLE_BOARD HUD must be ready synchronously at 1-1 load ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local shell = require("jumbalaya-engine.shell")
local Presentation = require("word_game.model.presentation")
local board_prime = require("word_game.ui.table.board_prime")

local function install_table_board_ui()
	mock_env.setup()
	mock_env.ensure_card_class()

	_G.WORD_GAME_UI = require("word_game.ui.facade.exports")
	require("word_game.ui.presentation.install").install(_G.WORD_GAME_UI, _G.WORD_GAME or require("word_game"))
	require("word_game.ui.callbacks.table_controls")

	local game = shell.game()
	game.C = game.C or {}
	game.C.CLEAR = game.C.CLEAR or { 0, 0, 0, 0 }
	game.C.RED = game.C.RED or { 1, 0, 0.4, 1 }
	game.C.BLUE = game.C.BLUE or { 0.2, 0.5, 1, 1 }
	game.C.WHITE = game.C.WHITE or { 1, 1, 1, 1 }
	game.C.DYN_UI = game.C.DYN_UI or { MAIN = { 0.22, 0.32, 0.35, 1 } }
	game.C.UI = game.C.UI or {}
	game.C.UI.TEXT_LIGHT = game.C.UI.TEXT_LIGHT or { 1, 1, 1, 1 }
	game.C.UI.BUTTON_HOVER = game.C.UI.BUTTON_HOVER or { 1, 1, 1, 0.2 }
	if not _G.get_hand_area_width then
		function get_hand_area_width(hand_size)
			local spacing = game.HAND_CARD_SPACING or 0.78
			return game.CARD_W + math.max(hand_size - 1, 0) * game.CARD_W * spacing
		end
	end

	game.STAGE = game.STAGES.RUN
	game.STATE = game.STATES.TABLE_BOARD
	game.STATE_COMPLETE = true
	game.TILESCALE = game.TILESCALE or 1
	game.TILESIZE = game.TILESIZE or 20
	game.TABLE_BOARD_SIDEBAR_WIDTH = game.TABLE_BOARD_SIDEBAR_WIDTH or 3.0
	game.ARGS = game.ARGS or {}

	game.SIDEBAR_ATTACH = game.SIDEBAR_ATTACH or EaseNode({
		T = { x = game.TILE_W - 3, y = 0, w = 3, h = game.TILE_H },
	})
	game.SIDEBAR_ATTACH.states = game.SIDEBAR_ATTACH.states or { drag = { can = false } }
	game.SIDEBAR_ATTACH.set_container = game.SIDEBAR_ATTACH.set_container or function() end
	game.SIDEBAR_ATTACH.translate_container = game.SIDEBAR_ATTACH.translate_container or function() end
	game.SIDEBAR_ATTACH.hard_set_T = game.SIDEBAR_ATTACH.hard_set_T or function() end

	game.PANEL_ATTACH = game.PANEL_ATTACH or EaseNode({
		T = { x = game.TILE_W - 3, y = 0, w = 3, h = game.TILE_H },
	})
	game.PANEL_ATTACH.states = game.PANEL_ATTACH.states or { drag = { can = false } }
	game.PANEL_ATTACH.hard_set_T = game.PANEL_ATTACH.hard_set_T or function() end

	game.PLAY_ATTACH = game.PLAY_ATTACH or EaseNode({
		T = { x = 0, y = 2, w = game.TILE_W - 3, h = game.TILE_H - 3.5 },
	})
	game.PLAY_ATTACH.hard_set_T = game.PLAY_ATTACH.hard_set_T or function() end

	game.LANG = game.LANG or {
		font = {
			FONT = love.graphics.newFont(),
			FONTSCALE = 0.12,
			squish = 1,
			TEXT_HEIGHT_SCALE = 0.7,
			TEXT_OFFSET = { x = 0, y = 0 },
		},
	}

	game.dealt_letters = CardPile(0, 0, game.CARD_W * 5, game.CARD_H, {
		type = "hand",
		card_limit = 7,
		selection_limit = 1,
	})
	game.dealt_letters.states = game.dealt_letters.states or { visible = true }
	game.dealt_letters.snap_VT = game.dealt_letters.snap_VT or function() end
	game.dealt_letters.hard_set_cards = game.dealt_letters.hard_set_cards or function() end

	game.draw_pile = CardPile(0, 0, game.CARD_W, game.CARD_H, {
		type = "deck",
		card_limit = 12,
	})
	game.draw_pile.states = game.draw_pile.states or { visible = true }
	game.draw_pile.snap_VT = game.draw_pile.snap_VT or function() end
	game.draw_pile.hard_set_T = game.draw_pile.hard_set_T or function() end
	game.draw_pile.hard_set_cards = game.draw_pile.hard_set_cards or function() end
	game.draw_pile.cards = game.draw_pile.cards or {}

	game.pattern_row = {
		area = {
			T = { x = 1, y = 3, w = 8, h = 1 },
			VT = { x = 1, y = 3, w = 8, h = 1 },
			cards = {},
			config = { type = "placement" },
			snap_VT = function() end,
			hard_set_cards = function() end,
		},
		apply_screen_position = function() end,
	}

	mock_env.publish_game({
		word_round = {
			set = 1,
			hand_index = 1,
			target = 100,
			mode = "jumble",
			jumble = {
				puzzle_index = 1,
				solved = false,
				total_score = 0,
				puzzle_points = 0,
				puzzle_multi = 1.0,
				puzzle_words = {},
				slots = {
					{ kind = "fixed", letter = "C" },
					{ kind = "span", cards = {}, min = 1, max = 5 },
					{ kind = "fixed", letter = "T" },
				},
				puzzle = { span = { "C", "T" }, min = 3, max = 7, kind = "span" },
			},
		},
		deck_left_count = 5,
	})
	game.ARGS.deck_left_count = 5

	return game
end

T.describe("table board boot", function()
	T.it("table_board_prime leaves HUD ready without waiting for update frames", function()
		local game = install_table_board_ui()
		game.ARGS.pending_layout = true

		local ok = board_prime.prime()
		T.assert_true(ok, "prime should report ready HUD")
		T.assert_true(board_prime.is_ready(game), "stage 1-1 HUD should be ready synchronously")
		T.assert_false(game.ARGS.pending_layout, "layout must not stay deferred after prime")
	end)

	T.it("presentation table_board_prime event matches direct prime", function()
		install_table_board_ui()
		Presentation.emit("table_board_prime")
		T.assert_true(board_prime.is_ready(), "presentation hook should prime HUD immediately")
	end)

	T.it("sidebar HUD registers on LIVE.UIBOX for immediate board-pass drawing", function()
		local game = install_table_board_ui()
		game.LIVE = game.LIVE or {}
		game.LIVE.UIBOX = game.LIVE.UIBOX or {}
		board_prime.prime()

		local hud = game.SIDEBAR_HUD
		T.assert_not_nil(hud)
		local listed = false
		for _, panel in pairs(game.LIVE.UIBOX) do
			if panel == hud then
				listed = true
				break
			end
		end
		T.assert_true(listed, "SIDEBAR_HUD should be registered on LIVE.UIBOX")
	end)

	T.it("sidebar rows and deck counter exist before first draw", function()
		install_table_board_ui()
		board_prime.prime()

		local hud = shell.game().SIDEBAR_HUD
		T.assert_not_nil(hud)
		for _, row_id in ipairs(board_prime.REQUIRED_SIDEBAR_ROWS) do
			T.assert_not_nil(hud:find_node_by_id(row_id), "missing sidebar row " .. row_id)
		end
		local counter = hud:find_node_by_id("text_deck_count")
		T.assert_not_nil(counter)
		T.assert_equal(counter.config.ref_value, "deck_left_count")
	end)

	T.it("play and shuffle controls are visible immediately after prime", function()
		install_table_board_ui()
		board_prime.prime()

		local tc = WORD_GAME_UI.TableControls
		T.assert_true(tc.buttons_present())
		local play_btn = tc.play_button_uie()
		T.assert_not_nil(play_btn)
		T.assert_true(play_btn.states.visible)
		T.assert_equal(play_btn.config.button, "play_placement_word")
	end)

	T.it("begin_run starts gameplay without scheduling a screen wipe overlay", function()
		mock_env.setup()
		local lifecycle = require("app.callbacks.controllers.run_lifecycle")
		local game = shell.game()
		game.TIMELINE = Scheduler()
		game.SETTINGS = game.SETTINGS or { paused = false }
		game.STAGES = game.STAGES or { RUN = 2, MAIN_MENU = 1 }
		game.STATES = game.STATES or { TABLE_BOARD = 20, MENU = 1 }
		game.STAGE = game.STAGES.MAIN_MENU
		game.discard_run = function() end
		game.start_run = function() end
		game.start_gameplay_board = function() end

		lifecycle.begin_run(nil, { run_mode = "classic" })

		T.assert_nil(game.screenwipe, "new run should not block HUD behind a screen wipe")
		T.assert_nil(game.INPUT.locks.wipe, "wipe lock should not be set when starting a run")
	end)
end)
