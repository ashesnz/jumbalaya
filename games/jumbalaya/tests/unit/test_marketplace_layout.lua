--[[ tests/unit/test_marketplace_layout.lua - Marketplace modal shell ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local shell = require("jumbalaya-engine.shell")

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

T.describe("marketplace layout", function()
	T.it("builds a dimmed modal with marketplace stage and close control", function()
		mock_env.setup()
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
		game.C.UI = game.C.UI or { BUTTON_HOVER = { 0.4, 0.4, 0.4, 1 } }

		local layout = require("word_game.ui.trade.layout")
		local def_mod = require("word_game.ui.trade.definition")
		local tree = def_mod.build_overlay_definition()
		local stage = find_def_node(tree, "trade_marketplace_stage")
		local frame = find_def_node(tree, "trade_marketplace_frame")
		local art = find_def_node(tree, "trade_marketplace_art")
		local close = find_def_node(tree, "trade_marketplace_close")
		local grid = find_def_node(tree, "trade_marketplace_grid")

		T.assert_not_nil(stage)
		T.assert_not_nil(frame)
		T.assert_not_nil(art)
		T.assert_not_nil(close)
		T.assert_equal(close.config.button, "trade_close")
		T.assert_not_nil(grid)

		local modal = layout.modal_frame()
		T.assert_true(math.abs(art.config.w / art.config.h - layout.art_aspect()) < 0.001)
		T.assert_true(math.abs(art.config.w - modal.w) < 0.02)
		T.assert_equal(stage.config.minw, modal.w)
		T.assert_equal(stage.config.minh, modal.h)
	end)
end)
