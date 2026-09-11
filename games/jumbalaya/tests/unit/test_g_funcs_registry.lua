--[[ tests/unit/test_g_funcs_registry.lua - UIBox callback catalog freeze ]]

local T = require("tests.framework")
local audit = require("tests.helpers.g_funcs_audit")

T.describe("UIBox callback registry", function()
	T.it("loads the catalog from types/funcs.lua", function()
		local catalog = audit.load_catalog()
		local count = 0
		for _ in pairs(catalog) do
			count = count + 1
		end
		T.assert_true(count >= 50, "expected a populated GameFuncName catalog")
	end)

	T.it("registers only cataloged callback names in app/ and word_game/", function()
		local unlisted = audit.unlisted_registrations()
		T.assert_equal(#unlisted, 0, "unlisted callbacks: " .. table.concat(unlisted, ", "))
	end)

	T.it("implements every cataloged callback in app/ or word_game/", function()
		local missing = audit.missing_implementations()
		T.assert_equal(#missing, 0, "missing callback impl: " .. table.concat(missing, ", "))
	end)

	T.it("lists every UIBox func/button binding in types/funcs.lua", function()
		local unlisted = audit.unlisted_ui_bindings()
		T.assert_equal(#unlisted, 0, "unlisted UI bindings: " .. table.concat(unlisted, ", "))
	end)

	T.it("registers every cataloged UIBox binding used in UI trees", function()
		local missing = audit.unregistered_ui_bindings()
		T.assert_equal(#missing, 0, "unregistered UI bindings: " .. table.concat(missing, ", "))
	end)
end)
