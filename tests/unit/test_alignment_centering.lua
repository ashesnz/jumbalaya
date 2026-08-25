--[[ tests/unit/test_alignment_centering.lua
     Re-alignment when the major moves: keeps the screen-wipe loading card
     centered on screen when Play is pressed (room attach shifts after the
     button jiggle, and the wipe view must follow instead of freezing).
]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")

T.describe("AnimNode align_to_major re-alignment", function()
	mock_env.setup()

	local function make_node(x, y, w, h)
		return AnimNode { T = { x = x, y = y, w = w, h = h } }
	end

	T.it("centers a node on its major at 'cm' alignment", function()
		local major = make_node(0, 0, 20, 11)
		local node = make_node(0, 0, 2, 1)
		node.Mid = node
		node:set_alignment{ major = major, type = "cm", offset = { x = 0, y = 0 } }

		node:align_to_major()

		T.assert_almost_equal(node.T.x, 9, 0.001, "node should be horizontally centered on the major")
		T.assert_almost_equal(node.T.y, 5, 0.001, "node should be vertically centered on the major")
	end)

	T.it("skips recomputation when nothing changed", function()
		local major = make_node(0, 0, 20, 11)
		local node = make_node(0, 0, 2, 1)
		node.Mid = node
		node:set_alignment{ major = major, type = "cm", offset = { x = 0, y = 0 } }
		node:align_to_major()

		-- External nudge with an unchanged major/mid must not be re-aligned.
		node.T.x = 99
		node:align_to_major()
		T.assert_almost_equal(node.T.x, 99, 0.001,
			"with no changes the pass should be skipped")
	end)

	T.it("re-aligns to follow the major after it moves (loading card stays centered)", function()
		local major = make_node(0, 0, 20, 11)
		local node = make_node(0, 0, 2, 1)
		node.Mid = node
		node:set_alignment{ major = major, type = "cm", offset = { x = 0, y = 0 } }
		node:align_to_major()

		-- The room attach shifts after the play-button press; no alignment
		-- offset or type change happens, but the node must still re-center.
		major.T.x = 4
		major.T.y = -2
		node:align_to_major()

		T.assert_almost_equal(node.T.x, 13, 0.001,
			"node must follow a moved major instead of freezing at its first position")
		T.assert_almost_equal(node.T.y, 3, 0.001,
			"node must follow a moved major vertically as well")
	end)

	T.it("re-aligns when the measured content size changes", function()
		local major = make_node(0, 0, 20, 11)
		local node = make_node(0, 0, 2, 1)
		node.Mid = node
		node:set_alignment{ major = major, type = "cm", offset = { x = 0, y = 0 } }
		node:align_to_major()

		node.T.w = 6
		node.Mid.T.w = 6
		node:align_to_major()

		T.assert_almost_equal(node.T.x, 7, 0.001,
			"node must re-center when its measured width changes")
	end)

	T.it("honours forced realignment via prev_offset reset (host bubble pattern)", function()
		local major = make_node(0, 0, 20, 11)
		local node = make_node(0, 0, 2, 1)
		node.Mid = node
		node:set_alignment{ major = major, type = "cm", offset = { x = 0, y = 0 } }
		node:align_to_major()

		node.alignment.prev_offset.x = nil
		node:align_to_major()
		T.assert_almost_equal(node.T.x, 9, 0.001,
			"clearing prev_offset.x must force a recomputation to the same center")
	end)
end)
