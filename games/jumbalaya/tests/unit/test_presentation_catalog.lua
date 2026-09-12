--[[ tests/unit/test_presentation_catalog.lua - Presentation bus event catalog freeze ]]

local T = require("tests.framework")
local audit = require("tests.helpers.presentation_catalog_audit")

T.describe("Presentation event catalog", function()
	T.it("loads the catalog from types/presentation_events.lua", function()
		local catalog = audit.load_catalog()
		local count = 0
		for _ in pairs(catalog) do
			count = count + 1
		end
		T.assert_true(count >= 40, "expected a populated PresentationEventName catalog")
	end)

	T.it("registers only cataloged event names in ui/presentation/handlers/", function()
		local unlisted = audit.unlisted_handlers()
		T.assert_equal(#unlisted, 0, "unlisted handlers: " .. table.concat(unlisted, ", "))
	end)

	T.it("handles every cataloged presentation event", function()
		local missing = audit.missing_handlers()
		T.assert_equal(#missing, 0, "missing handlers: " .. table.concat(missing, ", "))
	end)

	T.it("lists every external Presentation.emit site in types/presentation_events.lua", function()
		local unlisted = audit.unlisted_emits()
		T.assert_equal(#unlisted, 0, "unlisted emits: " .. table.concat(unlisted, ", "))
	end)
end)
