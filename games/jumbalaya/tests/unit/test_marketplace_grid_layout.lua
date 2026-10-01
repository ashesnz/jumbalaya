--[[ tests/unit/test_marketplace_grid_layout.lua - Marketplace 4×3 grid inside modal art ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local shell = require("jumbalaya-engine.shell")

local function find_node(panel, id, node)
	node = node or panel.root_node
	if not node then return nil end
	if node.config and node.config.id == id then
		return node
	end
	for _, child in pairs(node.children or {}) do
		local found = find_node(panel, id, child)
		if found then return found end
	end
	return nil
end

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

T.describe("marketplace grid layout", function()
	T.it("defines four rows: cards (50%) then add, remove, modify", function()
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
		game.C = game.C or {}
		game.C.CLEAR = game.C.CLEAR or { 0, 0, 0, 0 }
		game.C.UI = game.C.UI or {
			BUTTON = { 0.1, 0.5, 0.4, 1 },
			BUTTON_HOVER = { 0.2, 0.6, 0.5, 1 },
			BUTTON_TEXT = { 1, 1, 1, 1 },
			BACKGROUND_INACTIVE = { 0.3, 0.3, 0.3, 1 },
			TEXT_INACTIVE = { 0.5, 0.5, 0.5, 1 },
		}
		game.C.RED = game.C.RED or { 1, 0, 0, 1 }
		game.C.WHITE = game.C.WHITE or { 1, 1, 1, 1 }
		game.C.GOLD = game.C.GOLD or { 1, 0.8, 0, 1 }

		local layout = require("word_game.ui.trade.layout")
		local offer = require("word_game.ui.trade.offer")
		local session_state = require("word_game.ui.trade.session_state")
		offer.prepare()

		local frame = layout.modal_frame()
		local grid_mod = require("word_game.ui.trade.columns")
		local grid_def = grid_mod.build_grid(frame)
		local cards_row = find_def_node(grid_def, "trade_marketplace_cards_row")
		local add_row = find_def_node(grid_def, "trade_marketplace_add_row")
		local remove_row = find_def_node(grid_def, "trade_marketplace_remove_row")
		local modify_row = find_def_node(grid_def, "trade_marketplace_modify_row")

		T.assert_not_nil(cards_row)
		T.assert_not_nil(add_row)
		T.assert_not_nil(remove_row)
		T.assert_not_nil(modify_row)
		T.assert_equal(#(cards_row.nodes or {}), 3)
		T.assert_equal(#(add_row.nodes or {}), 3)
		T.assert_true(math.abs(cards_row.config.minh - frame.h * 0.5) < 0.02)
		T.assert_true(math.abs(add_row.config.minh - frame.h * (0.5 / 3)) < 0.02)

		local def_mod = require("word_game.ui.trade.definition")
		local tree = def_mod.build_overlay_definition()
		local stage = find_def_node(tree, "trade_marketplace_stage")
		local art = find_def_node(tree, "trade_marketplace_art")
		T.assert_not_nil(stage)
		T.assert_not_nil(art)
		T.assert_nil(art.config.draw_layer)
		T.assert_equal(find_def_node(tree, "trade_marketplace_grid").config.draw_layer, 1)

		local grid = find_def_node(tree, "trade_marketplace_grid")
		T.assert_equal(grid.config.minw, frame.w)
		T.assert_equal(grid.config.minh, frame.h)
		T.assert_equal(stage.config.minw, frame.w)
		T.assert_equal(stage.config.minh, frame.h)

		session_state.teardown()
	end)
end)
