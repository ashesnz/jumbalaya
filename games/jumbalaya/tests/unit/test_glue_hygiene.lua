--[[ tests/unit/test_glue_hygiene.lua - Phase 10a glue hygiene static scans ]]

local T = require("tests.framework")
local audit = require("tests.helpers.glue_hygiene_audit")

T.describe("glue hygiene (Phase 10a)", function()
	T.it("model glue routes layout refresh through layout/request.lua", function()
		local violations = audit.model_pending_layout_violations()
		T.assert_equal(#violations, 0, table.concat(violations, ", "))
	end)

	T.it("model glue does not call WORD_GAME_UI or Funcs.dispatch", function()
		local violations = audit.model_ui_boundary_violations()
		T.assert_equal(#violations, 0, table.concat(violations, ", "))
	end)
end)
