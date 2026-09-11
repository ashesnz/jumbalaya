--[[ tests/unit/test_phase7_bootstrap.lua - Phase 7 slim bootstrap wiring ]]

local T = require("tests.framework")

T.describe("Phase 7 Bootstrap", function()
	T.it("loads engine_adapter orchestration modules", function()
		T.assert_not_nil(require("app.bootstrap.engine_adapter"))
		T.assert_not_nil(require("app.bootstrap.runtime_boot"))
		T.assert_not_nil(require("app.bootstrap.presentation_boot"))
		T.assert_not_nil(require("app.bootstrap.store_boot"))
	end)

	T.it("bootstrap.lua delegates to engine_adapter", function()
		local adapter = require("app.bootstrap.engine_adapter")
		T.assert_not_nil(adapter.install)
	end)
end)
