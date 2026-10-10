--[[ tests/unit/test_uit_freeze.lua - No new game().UI integer trees ]]

local T = require("tests.framework")
local audit = require("tests.helpers.uit_audit")

T.describe("UIT freeze", function()
	T.it("word_game/ui/ does not author n = game().UI.* outside the allowlist", function()
		local violations = audit.violations()
		T.assert_equal(#violations, 0, "new UIT trees: " .. table.concat(violations, ", "))
	end)

	T.it("UIT allowlist has no stale entries", function()
		local stale = audit.stale_allowlist()
		T.assert_equal(#stale, 0, "stale allowlist: " .. table.concat(stale, ", "))
	end)
end)
