--[[ tests/unit/test_core_purity.lua - jumbalaya_core headless isolation freeze ]]

local T = require("tests.framework")
local audit = require("tests.helpers.core_purity_audit")

T.describe("jumbalaya_core purity", function()
	T.it("has no Love2D, app/, word_game/, or shell globals in source", function()
		local violations = audit.violations()
		T.assert_equal(#violations, 0, "core purity violations: " .. table.concat(violations, "; "))
	end)
end)
