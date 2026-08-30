--[[ tests/unit/test_atlas_paths.lua - AlphaCards-style 1x/2x path resolution ]]

local T = require("tests.framework")
local AtlasPaths = require("app.startup.atlas_paths")

T.describe("atlas paths", function()
	T.it("selects 1x folder when texture_scaling is 1", function()
		T.assert_equal(AtlasPaths.scale_suffix(1), "1x")
		T.assert_equal(AtlasPaths.dpiscale_for_source("1x", 1, "letters"), 1)
	end)

	T.it("selects 2x folder when texture_scaling is 2", function()
		T.assert_equal(AtlasPaths.scale_suffix(2), "2x")
		T.assert_equal(AtlasPaths.dpiscale_for_source("2x", 2, "letters"), 2)
	end)

	T.it("uses legacy dpiscale rules when only resources/assets exists", function()
		T.assert_equal(AtlasPaths.dpiscale_for_source("legacy", 1, "letters"), 2)
		T.assert_equal(AtlasPaths.dpiscale_for_source("legacy", 1, "playing_back"), 1)
	end)
end)
