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

	T.it("constructs sidebar HUD without plays left odometer and with clean unboxed word list", function()
		local sidebar_fn = require("word_game.ui.sidebar")
		local sidebar = sidebar_fn()
		G.GAME.table_word_history = {}

		local hud = sidebar.hud_definition()
		T.assert_not_nil(hud, "HUD definition should exist")

		-- Verify no plays_odometer node in HUD definition
		local function has_id(node, target_id)
			if node.config and node.config.id == target_id then return true end
			for _, child in pairs(node.nodes or {}) do
				if type(child) == "table" and has_id(child, target_id) then return true end
			end
			return false
		end

		T.assert_false(has_id(hud, "plays_odometer"), "Plays left odometer must be completely removed")
		T.assert_true(has_id(hud, "row_embedded_list"), "Embedded word list row must exist")

		-- Add puzzle fixed letters to sidebar history
		sidebar:add_play("C _ T", 24)
		sidebar:add_play("_ A R", 18)

		local nodes = sidebar.list_nodes()
		T.assert_equal(#nodes, 2, "Should have exactly 2 nodes for 2 puzzle plays")
		T.assert_equal(G.GAME.table_word_history[1].word, "C _ T")
		T.assert_equal(G.GAME.table_word_history[1].score, 24)
		T.assert_equal(G.GAME.table_word_history[2].word, "_ A R")
		T.assert_equal(G.GAME.table_word_history[2].score, 18)

		-- Verify unboxed (clear colour, no emboss)
		for _, row in ipairs(nodes) do
			T.assert_equal(row.config.colour, G.C.CLEAR, "Word row must not have a box background colour")
			T.assert_nil(row.config.emboss, "Word row must not have box shadow emboss")
		end

		-- Verify node order inside row_vault_fill has row_vault_spacer before row_deck
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
