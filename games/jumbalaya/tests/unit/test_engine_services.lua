--[[ tests/unit/test_engine_services.lua - jumbalaya-engine services layout ]]

local T = require("tests.framework")
local Store = require("jumbalaya_core.store")

T.describe("engine services", function()
	T.it("loads service modules from jumbalaya-engine.services.*", function()
		T.assert_not_nil(require("jumbalaya-engine.services.context"))
		T.assert_not_nil(require("jumbalaya-engine.services.renderer"))
		T.assert_not_nil(require("jumbalaya-engine.services.input"))
		T.assert_not_nil(require("jumbalaya-engine.services.audio"))
		T.assert_not_nil(require("jumbalaya-engine.services.clock"))
		T.assert_not_nil(require("jumbalaya-engine.services.event_bus"))
	end)

	T.it("Context bundles store-backed services", function()
		local Engine = require("jumbalaya-engine")
		local store = Store.new()
		local ctx = Engine.Context.new({ store = store })
		T.assert_equal(ctx.store, store)
		T.assert_not_nil(ctx.renderer)
		T.assert_not_nil(ctx.input)
		T.assert_not_nil(ctx.audio)
		T.assert_not_nil(ctx.clock)
		T.assert_not_nil(ctx.events)
	end)

	T.it("repo-root shim mounts game assets when localization is missing", function()
		local paths = require("bootstrap_paths").resolve()
		if paths.game_root == paths.source then
			T.assert_not_nil(love.filesystem.getInfo("localization/en-us.lua"))
		else
			T.assert_not_nil(
				love.filesystem.getInfo("localization/en-us.lua"),
				"localization must be visible after bootstrap_paths.install"
			)
		end
	end)
end)
