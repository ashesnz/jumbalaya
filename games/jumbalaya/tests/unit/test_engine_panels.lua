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
end)
