--[[ tests/unit/test_phase8_layoutview_retirement.lua - Phase 8 PR-8 app/core/ui retirement ]]

local T = require("tests.framework")

T.describe("Phase 8 PR-8 LayoutView retirement", function()
	T.it("loads retained UI from jumbalaya-engine instead of app/core/ui", function()
		local RetainedUI = require("jumbalaya-engine.retained_ui")
		T.assert_not_nil(RetainedUI.create)
		T.assert_not_nil(RetainedUI.RetainedPanel)
	end)

	T.it("ViewHost wraps retained panels for app overlays", function()
		local ViewHost = require("jumbalaya-engine.view_host")
		local host = ViewHost.create({
			definition = { n = G.UI.ROOT, config = { align = "cm" }, nodes = {} },
			config = { align = "cm", major = G.ROOM_ATTACH },
		})
		T.assert_not_nil(host)
		T.assert_not_nil(host._inner)
		host:remove()
	end)
end)
