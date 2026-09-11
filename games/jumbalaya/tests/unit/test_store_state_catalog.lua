--[[ tests/unit/test_store_state_catalog.lua - Run-state field catalog freeze ]]

local T = require("tests.framework")
local audit = require("tests.helpers.store_state_audit")

T.describe("run-state catalog", function()
	T.it("loads declared fields from types/store.lua", function()
		local catalog = audit.load_catalog()
		T.assert_true(catalog.GameRunState.word_round == true)
		T.assert_true(catalog.GameRunState.timeline_seconds == true)
	end)

	T.it("uses only cataloged top-level run-state keys in patches and reducers", function()
		local undeclared = audit.undeclared_run_state_keys()
		T.assert_equal(#undeclared, 0, "undeclared run-state keys: " .. table.concat(undeclared, ", "))
	end)
end)
