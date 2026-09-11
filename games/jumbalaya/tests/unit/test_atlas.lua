--[[ tests/unit/test_atlas.lua - Atlas path and dpiscale resolution ]]

local T = require("tests.framework")
local AtlasPaths = require("app.startup.atlas_paths")
local AtlasDpiscale = require("app.startup.atlas_dpiscale")

T.describe("atlas loading", function()
	T.it("selects 1x and 2x folders from texture_scaling", function()
		T.assert_equal(AtlasPaths.scale_suffix(1), "1x")
		T.assert_equal(AtlasPaths.dpiscale_for_source("1x", 1, "letters"), 1)
		T.assert_equal(AtlasPaths.scale_suffix(2), "2x")
		T.assert_equal(AtlasPaths.dpiscale_for_source("2x", 2, "letters"), 2)
	end)

	T.it("uses legacy dpiscale rules when only resources/assets exists", function()
		T.assert_equal(AtlasPaths.dpiscale_for_source("legacy", 1, "letters"), 2)
		T.assert_equal(AtlasPaths.dpiscale_for_source("legacy", 1, "playing_back"), 1)
	end)

	T.it("loads retina sprite atlases at dpiscale 2 on mobile", function()
		T.assert_true(AtlasDpiscale.is_retina_atlas("letters"))
		T.assert_equal(AtlasDpiscale.for_atlas("letters", 1), 2)
		T.assert_equal(AtlasDpiscale.for_atlas("letters", 2), 2)
	end)

	T.it("keeps native-resolution loading for full-bleed backgrounds", function()
		T.assert_true(AtlasDpiscale.is_native_atlas("playing_back"))
		T.assert_equal(AtlasDpiscale.for_atlas("playing_back", 1), 1)
		T.assert_equal(AtlasDpiscale.for_atlas("title_garden", 2), 1)
	end)
end)
