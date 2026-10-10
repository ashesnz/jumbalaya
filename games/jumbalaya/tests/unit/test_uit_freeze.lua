--[[ tests/unit/test_uit_freeze.lua - No new game().UI integer trees ]]

local T = require("tests.framework")
local audit = require("tests.helpers.uit_audit")

T.describe("UIT freeze", function()
	T.it("word_game/ui/ does not author n = game().UI.* trees", function()
		local violations = audit.violations()
		T.assert_equal(#violations, 0, "new UIT trees: " .. table.concat(violations, ", "))
	end)
end)
