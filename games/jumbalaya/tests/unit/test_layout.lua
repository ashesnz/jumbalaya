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
end)
