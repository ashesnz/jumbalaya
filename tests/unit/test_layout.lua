--[[ tests/unit/test_layout.lua
     Tests for layout dimensions, sidebar fixed width, and button alignment geometry.
]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("Layout & Sidebar Geometry (word_game.ui.layout)", function()
	mock_env.reset_game()
	local layout = require("word_game.ui.layout")

	T.it("uses fixed sidebar width", function()
		T.assert_equal(layout.sidebar_width(), 3.0, "Sidebar width should be fixed at 3.0 tiles")
	end)

	T.it("calculates sidebar fraction relative to TILE_W", function()
		G.TILE_W = 20
		local frac = layout.sidebar_frac()
		T.assert_almost_equal(frac, 3.0 / 20, 0.0001, "Sidebar fraction should be 3.0 / 20 = 0.15")
	end)

	T.it("constructs sidebar HUD with vault fill and deck row", function()
		local sidebar_fn = require("word_game.ui.sidebar")
		local sidebar = sidebar_fn()

		local hud = sidebar.hud_definition()
		T.assert_not_nil(hud, "HUD definition should exist")

		local fill_node
		local function find_fill(node)
			if node.config and node.config.id == "row_vault_fill" then
				fill_node = node
				return
			end
			for _, child in pairs(node.nodes or {}) do
				if type(child) == "table" then find_fill(child) end
			end
		end
		find_fill(hud)
		T.assert_not_nil(fill_node, "row_vault_fill should exist")

		local idx_spacer, idx_deck
		for i, child in ipairs(fill_node.nodes or {}) do
			if child.config then
				if child.config.id == "row_vault_spacer" then idx_spacer = i end
				if child.config.id == "row_deck" then idx_deck = i end
			end
		end
		T.assert_not_nil(idx_spacer, "row_vault_spacer should exist")
		T.assert_not_nil(idx_deck, "row_deck should exist")
		T.assert_true(idx_spacer < idx_deck, "Spacer must be before deck to pin deck to bottom")
	end)
end)
