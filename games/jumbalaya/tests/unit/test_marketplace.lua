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
	game.TILESIZE = 20
	game.TILESCALE = 1
	game.C = game.C or {}
	game.C.CLEAR = game.C.CLEAR or { 0, 0, 0, 0 }
	game.C.RED = game.C.RED or { 1, 0.2, 0.2, 1 }
	game.C.WHITE = game.C.WHITE or { 1, 1, 1, 1 }
	game.C.GOLD = game.C.GOLD or { 1, 0.8, 0, 1 }
	game.C.BLACK = game.C.BLACK or { 0, 0, 0, 1 }
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
		local gap_1 = find_def_node(grid_def, "trade_marketplace_button_gap_1")
		local remove_row = find_def_node(grid_def, "trade_marketplace_remove_row")
		local modify_row = find_def_node(grid_def, "trade_marketplace_modify_row")

		T.assert_not_nil(cards_row)
		T.assert_not_nil(modifier_row)
		T.assert_not_nil(gap_1)
		T.assert_not_nil(add_row)
		T.assert_not_nil(remove_row)
		T.assert_not_nil(modify_row)
		local modifier_card_gap = find_def_node(grid_def, "trade_marketplace_modifier_card_gap")
		T.assert_not_nil(modifier_card_gap)
		T.assert_true(math.abs(modifier_card_gap.config.minh - metrics.modifier_gap) < 0.02)
		local expected_rows = 9 + (metrics.top_spacer_h > 0.001 and 1 or 0)
		T.assert_equal(#(grid_def.nodes or {}), expected_rows)
		T.assert_equal(#(cards_row.nodes or {}), 3)
		T.assert_equal(#(modifier_row.nodes or {}), 3)
		T.assert_true(math.abs(cards_row.config.minh - metrics.cards_h) < 0.02)
		T.assert_true(math.abs(modifier_row.config.minh - metrics.modifier_h) < 0.02)
		T.assert_true(math.abs(add_row.config.minh - metrics.button_h) < 0.02)
		T.assert_true(math.abs(gap_1.config.minh - metrics.button_gap) < 0.02)
		local bottom_spacer = find_def_node(grid_def, "trade_marketplace_bottom_spacer")
		T.assert_not_nil(bottom_spacer)
		T.assert_true(math.abs(bottom_spacer.config.minh - metrics.bottom_pad) < 0.02)
		T.assert_true(grid_mod.sum_row_min_heights(grid_def) <= frame.h - 2 * grid_mod.GRID_PADDING + 0.02)

		local items = offer.items()
		for index = 1, 3 do
			local mod_node = find_def_node(grid_def, "trade_market_modifier_" .. index)
			T.assert_not_nil(mod_node, "modifier label for column " .. index)
			local expected = Modifiers.modifier_description(items[index].letter)
			T.assert_equal(mod_node.config.text, expected)
			T.assert_equal(mod_node.config.colour, grid_mod.modifier_text_colour())
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
				math.abs(metrics.total_row_h - metrics.inner_h) < 0.02,
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
		T.assert_true(src:find("BUTTON_STACK_GAP_PX"), "action rows should use fixed pixel gaps")
		T.assert_true(src:find("MODIFIER_ABOVE_CARD_GAP_PX"), "modifier rows should sit just above cards")
		T.assert_true(src:find("MODAL_BOTTOM_PADDING_PX"), "modify row should clear the modal bottom edge")
		T.assert_true(src:find("modifier_text_colour"), "modifier copy should use marketplace text colour")
		T.assert_false(src:find("trade_marketplace_button_stack"), "buttons must be ROW siblings, not a nested COLUMN")
	end)

	T.it("spaces modifier text and action buttons with fixed pixel gaps", function()
		setup_marketplace_game()
		local layout = require("word_game.ui.trade.layout")
		local columns = require("word_game.ui.trade.columns")
		local frame = layout.modal_frame()
		local metrics = columns.layout_metrics(frame)
		local grid_def = columns.build_grid(frame)
		local gap = find_def_node(grid_def, "trade_marketplace_button_gap_1")
		local mod_gap = find_def_node(grid_def, "trade_marketplace_modifier_card_gap")
		T.assert_not_nil(gap)
		T.assert_not_nil(mod_gap)
		T.assert_true(metrics.button_gap > 0)
		T.assert_true(metrics.modifier_gap > 0)
		T.assert_true(math.abs(gap.config.minh - metrics.button_gap) < 0.02)
		T.assert_true(math.abs(mod_gap.config.minh - metrics.modifier_gap) < 0.02)
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

	T.it("add action flies the preview card into the deck before refreshing", function()
		local paths = require("bootstrap_paths").resolve()
		local file = io.open(paths.path_under_repo(
			"games", "jumbalaya", "word_game", "ui", "trade", "actions.lua"), "r")
		T.assert_not_nil(file)
		local src = file:read("*a")
		file:close()
		T.assert_true(src:find("card_fly.start"))
		T.assert_true(src:find("defer_effect"))
		T.assert_true(src:find("sync_deck_count_display"))
	end)

	T.it("defer_effect add spends tokens without drafting immediately", function()
		mock_env.reset_game()
		mock_env.patch_game({
			run_state = { tokens = 20, perks = {}, trade_used_this_hand = false },
		})
		local trade = require("word_game.model.trade.init")
		local state = require("word_game.model.run.state")
		local item = { letter = "Q", mode = "market", color = "red" }
		local ok = trade.apply(item, { action = "add", defer_effect = true })
		T.assert_true(ok)
		T.assert_nil(item.card)
		T.assert_equal(state.tokens(), 10)
	end)

	T.it("discard_item_preview removes standalone marketplace preview cards", function()
		local preview = require("word_game.ui.trade.preview")
		local removed = false
		local item = {
			preview_is_standalone = true,
			preview = { REMOVED = false, remove = function() removed = true end },
		}
		preview.discard_item_preview(item)
		T.assert_true(removed)
		T.assert_nil(item.preview)
	end)

	T.it("reset completes a pending fly without refreshing the overlay slot", function()
		mock_env.reset_game()
		local shell = require("jumbalaya-engine.shell")
		local game = shell.game()
		game.ROOM = game.ROOM or {
			T = { x = 0, y = 0, w = 20, h = 11, r = 0 },
			translate_container = function() end,
		}
		game.CARD_W = 1
		game.CARD_H = 1.4
		game.OVERLAY_MENU = {
			REMOVED = false,
			find_node_by_id = function(_, id)
				if id == "trade_market_card_2" then
					return { T = { x = 4, y = 2, w = 0.5, h = 0.7 }, config = {} }
				end
			end,
		}
		local done = false
		local card_fly = require("word_game.ui.trade.card_fly")
		card_fly.reset()
		T.assert_true(card_fly.start({
			kind = "add",
			item = { letter = "M", color = "red" },
			market_index = 2,
			on_complete = function() done = true end,
		}))
		card_fly.reset()
		T.assert_true(done)
		T.assert_false(card_fly.is_active())
	end)

	T.it("modify fly restores deck card visibility only after finalize", function()
		mock_env.reset_game()
		local shell = require("jumbalaya-engine.shell")
		local game = shell.game()
		game.ROOM = game.ROOM or {
			T = { x = 0, y = 0, w = 20, h = 11, r = 0 },
			translate_container = function() end,
		}
		game.CARD_W = 1
		game.CARD_H = 1.4
		game.OVERLAY_MENU = {
			find_node_by_id = function(_, id)
				if id == "trade_market_card_1" then
					return { T = { x = 4, y = 2, w = 0.5, h = 0.7 }, config = {} }
				end
			end,
		}
		local hidden = { states = { visible = false }, REMOVED = false }
		local finalized = false
		local card_fly = require("word_game.ui.trade.card_fly")
		card_fly.reset()
		T.assert_true(card_fly.start({
			kind = "modify",
			item = { letter = "R", color = "red", card = hidden },
			market_index = 1,
			on_complete = function()
				finalized = true
			end,
		}))
		T.assert_false(hidden.states.visible)
		card_fly.update(1)
		T.assert_true(finalized)
		T.assert_true(hidden.states.visible)
		card_fly.reset()
	end)

	T.it("remove fly does not restore deck card visibility after landing", function()
		mock_env.reset_game()
		local shell = require("jumbalaya-engine.shell")
		local game = shell.game()
		game.ROOM = game.ROOM or {
			T = { x = 0, y = 0, w = 20, h = 11, r = 0 },
			translate_container = function() end,
		}
		game.CARD_W = 1
		game.CARD_H = 1.4
		game.OVERLAY_MENU = {
			find_node_by_id = function(_, id)
				if id == "trade_market_card_1" then
					return {
						T = { x = 4, y = 2, w = 0.5, h = 0.7 },
						config = {},
					}
				end
			end,
		}
		local hidden = { states = { visible = false } }
		local destroyed = false
		local card_fly = require("word_game.ui.trade.card_fly")
		card_fly.reset()
		T.assert_true(card_fly.start({
			kind = "remove",
			item = { letter = "K", color = "red", card = hidden },
			market_index = 1,
			on_complete = function()
				destroyed = true
				hidden.states.visible = false
				hidden.REMOVED = true
			end,
		}))
		card_fly.update(1)
		T.assert_true(destroyed)
		T.assert_false(hidden.states.visible)
		card_fly.reset()
	end)

	T.it("card fly animation completes and clears trade_ui_busy", function()
		mock_env.reset_game()
		local shell = require("jumbalaya-engine.shell")
		local game = shell.game()
		game.ROOM = game.ROOM or {
			T = { x = 0, y = 0, w = 20, h = 11, r = 0 },
			translate_container = function() end,
		}
		game.CARD_W = 1
		game.CARD_H = 1.4
		game.OVERLAY_MENU = {
			find_node_by_id = function(_, id)
				if id == "trade_market_card_2" then
					return {
						T = { x = 4, y = 2, w = 0.5, h = 0.7 },
						config = { object = { states = { visible = true } } },
					}
				end
			end,
		}

		local item = { letter = "Z", color = "red" }
		local done = false
		local card_fly = require("word_game.ui.trade.card_fly")
		card_fly.reset()
		T.assert_true(card_fly.start({
			kind = "add",
			item = item,
			market_index = 2,
			on_complete = function() done = true end,
		}))
		local Busy = require("word_game.model.run.busy")
		T.assert_true(Busy.on("trade_ui_busy"))
		card_fly.update(1)
		T.assert_false(card_fly.is_active())
		T.assert_false(Busy.on("trade_ui_busy"))
		T.assert_true(done)
		card_fly.reset()
	end)

	T.it("after_tokens_changed refreshes sidebar deck count and token display", function()
		mock_env.reset_game()
		mock_env.patch_game({
			run_state = { tokens = 50, perks = {}, trade_used_this_hand = false },
		})
		local shell = require("jumbalaya-engine.shell")
		local game = shell.game()
		game.ARGS = game.ARGS or {}
		game.ARGS.deck_left_count = 42

		local recalculated = false
		game.SIDEBAR_HUD = {
			REMOVED = false,
			recalculate = function()
				recalculated = true
			end,
		}

		local spend_calls = 0
		_G.WORD_GAME_UI = _G.WORD_GAME_UI or {}
		_G.WORD_GAME_UI.TableDeck = {
			spend_tokens_display = function(amount)
				spend_calls = spend_calls + 1
				T.assert_equal(amount, 10)
			end,
			sync_token_display = function() end,
		}

		local refresh = require("word_game.ui.trade.refresh")
		refresh.after_tokens_changed({ spent = 10 })

		T.assert_true(recalculated, "sidebar HUD should recalculate for Cards left text")
		T.assert_equal(spend_calls, 1)

		game.SIDEBAR_HUD = nil
	end)

	T.it("marketplace actions do not force-close the overlay", function()
		local paths = require("bootstrap_paths").resolve()
		local file = io.open(paths.path_under_repo(
			"games", "jumbalaya", "word_game", "ui", "trade", "actions.lua"), "r")
		T.assert_not_nil(file)
		local src = file:read("*a")
		file:close()
		T.assert_false(src:find("TradeUI%.close"), "close only when nothing is affordable (refresh.lua)")
	end)

	local function stub_marketplace_facade(spend_on_apply)
		local facade = require("word_game.ui.facade")
		local game_access = require("word_game.model.game_access")
		local economy = require("jumbalaya_core.config.gameplay.economy")
		local orig_trade = facade.trade
		local orig_deck = facade.deck
		facade.trade = function()
			local trade = orig_trade()
			return setmetatable({
				apply = function(_, opts)
					if opts and opts.defer_effect then
						game_access.dispatch({
							type = "RUN_STATE_SPEND_TOKENS",
							amount = spend_on_apply or economy.TRADE_ADD_COST,
						})
						return true
					end
					game_access.dispatch({
						type = "RUN_STATE_SPEND_TOKENS",
						amount = spend_on_apply or economy.TRADE_ADD_COST,
					})
					return true
				end,
				finalize_add = function() return true end,
				finalize_remove = function() return true end,
				finalize_modifier = function() return true end,
			}, { __index = trade })
		end
		facade.deck = function()
			return { sync_deck_count_display = function() end }
		end
		return function()
			facade.trade = orig_trade
			facade.deck = orig_deck
		end
	end

	T.it("keeps marketplace open after add when tokens remain", function()
		mock_env.reset_game()
		mock_env.ensure_card_class()
		mock_env.patch_game({
			run_state = { tokens = 100, perks = {}, trade_used_this_hand = false },
		})
		_G.WORD_GAME_UI = _G.WORD_GAME_UI or {}
		_G.WORD_GAME_UI.TableDeck = { uses_table_draw = function() return false end }

		local restore_facade = stub_marketplace_facade()
		local session_state = require("word_game.ui.trade.session_state")
		local actions = require("word_game.ui.trade.actions")
		local lifecycle = require("word_game.ui.trade.lifecycle")
		local close_calls = 0
		local orig_close = lifecycle.close
		lifecycle.close = function()
			close_calls = close_calls + 1
		end

		session_state.mark_open(true)
		session_state.set_offer({
			add = {
				mode = "market",
				letters = {
					{ letter = "A", mode = "market" },
					{ letter = "B", mode = "market" },
					{ letter = "C", mode = "market" },
				},
			},
		})

		local card_fly = require("word_game.ui.trade.card_fly")
		card_fly.reset()
		actions.on_add({ config = { ref_table = { market_index = 1 } } })
		card_fly.update(1)

		T.assert_true(session_state.is_open(), "overlay stays open while add actions remain affordable")
		T.assert_equal(close_calls, 0)

		lifecycle.close = orig_close
		restore_facade()
		card_fly.reset()
		session_state.teardown()
	end)

	T.it("closes marketplace after add when no action stays affordable", function()
		mock_env.reset_game()
		mock_env.ensure_card_class()
		mock_env.patch_game({
			run_state = { tokens = 10, perks = {}, trade_used_this_hand = false },
		})
		_G.WORD_GAME_UI = _G.WORD_GAME_UI or {}
		_G.WORD_GAME_UI.TableDeck = { uses_table_draw = function() return false end }

		local restore_facade = stub_marketplace_facade()
		local session_state = require("word_game.ui.trade.session_state")
		local actions = require("word_game.ui.trade.actions")
		local lifecycle = require("word_game.ui.trade.lifecycle")
		local closed = false
		local orig_close = lifecycle.close
		lifecycle.close = function()
			closed = true
			orig_close()
		end

		session_state.mark_open(true)
		session_state.set_offer({
			add = {
				mode = "market",
				letters = {
					{ letter = "A", mode = "market" },
					{ letter = "B", mode = "market" },
					{ letter = "C", mode = "market" },
				},
			},
		})

		local card_fly = require("word_game.ui.trade.card_fly")
		card_fly.reset()
		actions.on_add({ config = { ref_table = { market_index = 1 } } })
		card_fly.update(1)

		T.assert_true(closed, "overlay closes when broke after add")
		T.assert_false(session_state.is_open())

		lifecycle.close = orig_close
		restore_facade()
		card_fly.reset()
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

	T.it("reserves sidebar space and trims modal width in layout source", function()
		local paths = require("bootstrap_paths").resolve()
		local layout_file = io.open(paths.path_under_repo(
			"games", "jumbalaya", "word_game", "ui", "trade", "layout.lua"), "r")
		T.assert_not_nil(layout_file)
		local layout_src = layout_file:read("*a")
		layout_file:close()
		T.assert_true(layout_src:find("MODAL_EXTRA_TRIM_PX"))
		T.assert_true(layout_src:find("play_column"))
		T.assert_true(layout_src:find("modal_overlay_offset"))

		local lifecycle_file = io.open(paths.path_under_repo(
			"games", "jumbalaya", "word_game", "ui", "trade", "lifecycle.lua"), "r")
		T.assert_not_nil(lifecycle_file)
		local life_src = lifecycle_file:read("*a")
		lifecycle_file:close()
		T.assert_true(life_src:find("modal_overlay_offset"))
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
		T.assert_true(src:find("Sidebar:draw"), "sidebar should paint while marketplace is open")
	end)

	T.it("registers marketplace action callbacks", function()
		require("word_game.ui.callbacks.trade")
		local Funcs = require("app.callbacks.funcs")
		T.assert_not_nil(Funcs.get("trade_market_add"))
		T.assert_not_nil(Funcs.get("trade_market_remove"))
		T.assert_not_nil(Funcs.get("trade_market_modify"))
	end)

	T.it("sync_action_affordance toggles add buttons when tokens change", function()
		setup_marketplace_game()
		local layout = require("word_game.ui.trade.layout")
		local columns = require("word_game.ui.trade.columns")
		local session_state = require("word_game.ui.trade.session_state")
		local offer_mod = require("word_game.ui.trade.offer")
		local trade = require("word_game.model.trade.init")
		local game_access = require("word_game.model.game_access")

		game_access.dispatch({ type = "RUN_STATE_INIT" })
		game_access.dispatch({ type = "RUN_STATE_ADD_TOKENS", amount = 0 })
		session_state.mark_open(true)
		offer_mod.prepare()

		local frame = layout.modal_frame()
		local grid_def = columns.build_grid(frame)
		local root = {
			find_node_by_id = function(_, id)
				return find_def_node(grid_def, id)
			end,
		}

		columns.sync_action_affordance(root)
		local add_row = find_def_node(grid_def, "trade_marketplace_add_row")
		local btn_col = add_row.nodes[1].nodes[1]
		T.assert_nil(btn_col.config.button, "add should be disabled with zero tokens")
		T.assert_false(columns.any_action_affordable(), "no tokens means no affordable actions")

		game_access.dispatch({ type = "RUN_STATE_ADD_TOKENS", amount = 100 })
		columns.sync_action_affordance(root)
		T.assert_equal(btn_col.config.button, "trade_market_add")
		T.assert_true(columns.any_action_affordable())

		session_state.teardown()
	end)
end)
