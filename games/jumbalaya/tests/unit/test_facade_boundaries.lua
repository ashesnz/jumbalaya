--[[ tests/unit/test_facade_boundaries.lua - Facade import boundary freeze ]]

local T = require("tests.framework")
local audit = require("tests.helpers.facade_boundary_audit")

T.describe("facade import boundaries", function()
	T.it("app/ and devtools/ do not deep-require word_game.* (bootstrap wiring exempt)", function()
		local violations = audit.shell_boundary_violations()
		T.assert_equal(#violations, 0, "boundary violations: " .. table.concat(violations, ", "))
	end)

	T.it("word_game/ui/ does not deep-require word_game.model.* (use ui/facade)", function()
		local violations = audit.ui_model_boundary_violations()
		T.assert_equal(#violations, 0, "ui model violations: " .. table.concat(violations, ", "))
	end)

	T.it("word_game/model/ does not import word_game/ui/", function()
		local violations = audit.model_ui_boundary_violations()
		T.assert_equal(#violations, 0, "model ui violations: " .. table.concat(violations, ", "))
	end)
end)
