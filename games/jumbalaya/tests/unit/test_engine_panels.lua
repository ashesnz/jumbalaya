--[[ tests/unit/test_engine_panels.lua - jumbalaya-engine panel framework ]]

local T = require("tests.framework")

T.describe("engine panels", function()
	T.it("exports Panel create and ViewHost from jumbalaya-engine.panels", function()
		local Panels = require("jumbalaya-engine.panels")
		T.assert_not_nil(Panels.create)
		T.assert_not_nil(Panels.Panel)
		T.assert_not_nil(Panels.ViewHost)
		T.assert_not_nil(Panels.ViewHost.create)
	end)

	T.it("engine facade exposes Panels and ViewHost", function()
		local Engine = require("jumbalaya-engine")
		T.assert_not_nil(Engine.Panels)
		T.assert_not_nil(Engine.ViewHost)
	end)

	T.it("ViewHost __index does not recurse after remove or nested wrap", function()
		local ViewHost = require("jumbalaya-engine.panels.view_host")
		local inner = ViewHost.wrap({
			T = { x = 1 },
			VT = {},
			config = { id = "inner" },
			children = {},
			root_node = {},
			REMOVED = false,
		})
		local outer = ViewHost.wrap(inner)
		T.assert_equal(outer.T.x, 1)
		T.assert_nil(outer.no_such_field)
		outer:remove()
		T.assert_true(outer.REMOVED)
		T.assert_nil(outer.no_such_field)
		T.assert_nil(inner.no_such_field)
	end)
end)
