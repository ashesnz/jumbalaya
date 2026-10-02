--[[ tests/unit/test_marketplace.lua - Card Marketplace layout, offer, and actions ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local shell = require("jumbalaya-engine.shell")
local Modifiers = require("jumbalaya_core.cards.letter_modifiers")

local VOWELS = { A = true, E = true, I = true, O = true, U = true }

local function find_def_node(def, id)
	if not def then return nil end
	if def.config and def.config.id == id then
		return def
	end
	for _, child in ipairs(def.nodes or {}) do
		local found = find_def_node(child, id)
		if found then return found end
	end
	return nil
end

local function setup_marketplace_game()
	mock_env.setup()
	mock_env.ensure_card_class()
	require("word_game.ui.widgets.buttons")
	local game = shell.game()
	game.TEXTURE_ATLASES = game.TEXTURE_ATLASES or {}
	game.TEXTURE_ATLASES.marketplace_bg = {
		image = { getDimensions = function() return 1408, 768 end },
		px = 1408,
		py = 768,
	}
	game.UI = game.UI or {
		TEXT = 1, BOX = 2, COLUMN = 3, ROW = 4, OBJECT = 5, ROOT = 7, padding = 0,
	}
	game.C = game.C or {}
	game.C.CLEAR = game.C.CLEAR or { 0, 0, 0, 0 }
	game.C.RED = game.C.RED or { 1, 0.2, 0.2, 1 }
	game.C.WHITE = game.C.WHITE or { 1, 1, 1, 1 }
	game.C.GOLD = game.C.GOLD or { 1, 0.8, 0, 1 }
	game.C.UI = game.C.UI or {
		BUTTON = { 0.1, 0.5, 0.4, 1 },
		BUTTON_HOVER = { 0.2, 0.6, 0.5, 1 },
		BUTTON_TEXT = { 1, 1, 1, 1 },
		BACKGROUND_INACTIVE = { 0.3, 0.3, 0.3, 1 },
		TEXT_INACTIVE = { 0.5, 0.5, 0.5, 1 },
		TEXT_LIGHT = { 0.85, 0.85, 0.9, 1 },
	}
end

T.describe("marketplace", function()
	T.it("builds a dimmed modal with stage, art, grid, and close", function()
		setup_marketplace_game()
		local layout = require("word_game.ui.trade.layout")
		local def_mod = require("word_game.ui.trade.definition")
		local tree = def_mod.build_overlay_definition()
		local stage = find_def_node(tree, "trade_marketplace_stage")
		local art = find_def_node(tree, "trade_marketplace_art")
		local close = find_def_node(tree, "trade_marketplace_close")
		local grid = find_def_node(tree, "trade_marketplace_grid")

		T.assert_not_nil(stage)
		T.assert_not_nil(art)
		T.assert_not_nil(close)
		T.assert_not_nil(grid)
		T.assert_equal(close.config.button, "trade_close")
		T.assert_nil(art.config.draw_layer)
		T.assert_equal(grid.config.draw_layer, 1)

		local modal = layout.modal_frame()
		T.assert_true(math.abs(art.config.w / art.config.h - layout.art_aspect()) < 0.001)
		T.assert_equal(stage.config.minw, modal.w)
		T.assert_equal(stage.config.minh, modal.h)
	end)

	T.it("defines five grid rows: modifiers, cards, then add/remove/modify", function()
		mock_env.reset_game()
		mock_env.patch_game({
			run_state = { tokens = 100, perks = {}, trade_used_this_hand = false },
			seed_streams = { seed = "grid_test", key = 1 },
		})
		setup_marketplace_game()
		local layout = require("word_game.ui.trade.layout")
		local offer = require("word_game.ui.trade.offer")
		local session_state = require("word_game.ui.trade.session_state")
		offer.prepare()

		local frame = layout.modal_frame()
		local grid_mod = require("word_game.ui.trade.columns")
		local grid_def = grid_mod.build_grid(frame)
		local metrics = grid_mod.layout_metrics(frame)
		local cards_row = find_def_node(grid_def, "trade_marketplace_cards_row")
		local modifier_row = find_def_node(grid_def, "trade_marketplace_modifier_row")
		local add_row = find_def_node(grid_def, "trade_marketplace_add_row")
		local remove_row = find_def_node(grid_def, "trade_marketplace_remove_row")
		local modify_row = find_def_node(grid_def, "trade_marketplace_modify_row")

		T.assert_not_nil(cards_row)
		T.assert_not_nil(modifier_row)
		T.assert_not_nil(add_row)
		T.assert_not_nil(remove_row)
		T.assert_not_nil(modify_row)
		T.assert_equal(#(grid_def.nodes or {}), 5)
		T.assert_equal(#(cards_row.nodes or {}), 3)
		T.assert_equal(#(modifier_row.nodes or {}), 3)
		T.assert_equal(grid_def.nodes[1].config.id, "trade_marketplace_modifier_row")
		T.assert_equal(grid_def.nodes[2].config.id, "trade_marketplace_cards_row")
		T.assert_true(math.abs(cards_row.config.minh - metrics.cards_h) < 0.02)
		T.assert_true(math.abs(modifier_row.config.minh - metrics.modifier_h) < 0.02)
		T.assert_true(math.abs(add_row.config.minh - metrics.button_h) < 0.02)
		T.assert_true(grid_mod.sum_row_min_heights(grid_def) <= frame.h - 2 * grid_mod.GRID_PADDING + 0.02)

		local items = offer.items()
		for index = 1, 3 do
			local mod_node = find_def_node(grid_def, "trade_market_modifier_" .. index)
			T.assert_not_nil(mod_node, "modifier label for column " .. index)
			local expected = Modifiers.modifier_description(items[index].letter)
			T.assert_equal(mod_node.config.text, expected)
		end

		local first_col = add_row.nodes and add_row.nodes[1]
		local btn_col = first_col and first_col.nodes and first_col.nodes[1]
		T.assert_equal(btn_col.config.ref_table.market_index, 1)
		T.assert_equal(btn_col.config.button, "trade_market_add")
		T.assert_equal(btn_col.config.minw, metrics.button_minw)
		T.assert_true(btn_col.config.maxw <= metrics.col_w + 0.001)

		session_state.teardown()
	end)

	T.it("keeps grid rows and controls inside the modal frame across room sizes", function()
		setup_marketplace_game()
		local layout = require("word_game.ui.trade.layout")
		local columns = require("word_game.ui.trade.columns")
		local game = shell.game()
		local rooms = {
			{ w = 20, h = 11 },
			{ w = 16, h = 9 },
			{ w = 24, h = 13 },
			{ w = 12, h = 7 },
		}
		for _, room in ipairs(rooms) do
			game.ROOM.T.w = room.w
			game.ROOM.T.h = room.h
			local frame = layout.modal_frame()
			local metrics = columns.layout_metrics(frame)
			T.assert_true(
				metrics.total_row_h <= metrics.inner_h + 0.001,
				string.format("row stack taller than frame (%.2f > %.2f) at %dx%d",
					metrics.total_row_h, metrics.inner_h, room.w, room.h)
			)
			T.assert_true(metrics.button_minw <= metrics.col_w + 0.001)
			T.assert_true(metrics.market_card_w <= metrics.col_w + 0.001)

			local grid_def = columns.build_grid(frame)
			T.assert_equal(grid_def.config.minw, frame.w)
			T.assert_equal(grid_def.config.maxw, frame.w)
			T.assert_equal(grid_def.config.minh, frame.h)
			T.assert_equal(grid_def.config.maxh, frame.h)
			T.assert_true(columns.sum_row_min_heights(grid_def) <= frame.h - 2 * columns.GRID_PADDING + 0.02)

			for _, row in ipairs(grid_def.nodes or {}) do
				T.assert_equal(row.config.maxw, frame.w)
				T.assert_true((row.config.minh or 0) <= frame.h)
			end

			for col_index = 1, 3 do
				local card_node = find_def_node(grid_def, "trade_market_card_" .. col_index)
				if card_node and card_node.config.w then
					T.assert_true(card_node.config.w <= metrics.col_w + 0.001)
				end
			end
		end
	end)

	T.it("layout source constrains marketplace grid to the art frame", function()
		local paths = require("bootstrap_paths").resolve()
		local file = io.open(paths.path_under_repo(
			"games", "jumbalaya", "word_game", "ui", "trade", "columns.lua"), "r")
		T.assert_not_nil(file)
		local src = file:read("*a")
		file:close()
		T.assert_true(src:find("layout_metrics"), "grid should derive sizes from layout_metrics")
		T.assert_true(src:find("maxh = frame%.h"), "grid should cap height to the modal frame")
		T.assert_true(src:find("ACTION_BUTTON_WIDTH_FRAC"), "buttons should scale to column width")
	end)

	T.it("does not alias live deck cards for marketplace previews", function()
		local paths = require("bootstrap_paths").resolve()
		local file = io.open(paths.path_under_repo(
			"games", "jumbalaya", "word_game", "ui", "trade", "preview.lua"), "r")
		T.assert_not_nil(file)
		local src = file:read("*a")
		file:close()
		T.assert_false(src:find("item%.preview = item%.card"), "deck cards must not be embedded in the overlay")
	end)

	T.it("rolls three unique letters with one vowel and two consonants", function()
		mock_env.reset_game()
		mock_env.patch_game({
			run_state = { tokens = 100, perks = {}, trade_used_this_hand = false },
			seed_streams = { seed = "market_test", key = 1 },
		})
		local trade = require("word_game.model.trade")
		local offer = trade.roll_offer()
		local letters = offer.add.letters
		T.assert_equal(#letters, 3)

		local vowel_count, consonant_count = 0, 0
		local seen = {}
		for _, item in ipairs(letters) do
			T.assert_false(seen[item.letter], "letters should be unique: " .. item.letter)
			seen[item.letter] = true
			if VOWELS[item.letter] then vowel_count = vowel_count + 1
			else consonant_count = consonant_count + 1 end
		end
		T.assert_equal(vowel_count, 1)
		T.assert_equal(consonant_count, 2)
	end)

	T.it("apply add spends tokens when affordable", function()
		mock_env.reset_game()
		mock_env.patch_game({
			run_state = { tokens = 5, perks = {}, trade_used_this_hand = false },
		})
		local trade = require("word_game.model.trade")
		local ok, err = trade.apply({ letter = "Q", mode = "market" }, { action = "add" })
		T.assert_false(ok)
		T.assert_equal(err, "Not enough tokens")
	end)

	T.it("greys remove when the letter is not in the deck", function()
		mock_env.reset_game()
		local trade = require("word_game.model.trade")
		T.assert_false(trade.can_remove({ letter = "Q", card = nil }))
	end)

	T.it("paints the marketplace modal after table chrome", function()
		local paths = require("bootstrap_paths").resolve()
		local file = io.open(paths.path_under_repo("games", "jumbalaya", "app", "session", "draw_passes.lua"), "r")
		T.assert_not_nil(file)
		local src = file:read("*a")
		file:close()
		local modal_pos = src:find("draw_modal_on_top")
		local pointer_pos = src:find("game.POINTER:draw")
		T.assert_true(modal_pos and pointer_pos and modal_pos < pointer_pos)
		T.assert_true(src:find("trade_marketplace_open"))
	end)

	T.it("registers marketplace action callbacks", function()
		require("word_game.ui.callbacks.trade")
		local Funcs = require("app.callbacks.funcs")
		T.assert_not_nil(Funcs.get("trade_market_add"))
		T.assert_not_nil(Funcs.get("trade_market_remove"))
		T.assert_not_nil(Funcs.get("trade_market_modify"))
	end)
end)
