--[[ tests/unit/test_legacy_shims.lua - No config re-export proxy files ]]

local T = require("tests.framework")
local audit = require("tests.helpers.legacy_shim_audit")

T.describe("legacy shim purge", function()
	T.it("does not keep word_game/config/gameplay round/economy proxy files", function()
		local present = audit.forbidden_proxy_files_present()
		T.assert_equal(#present, 0, "proxy files remain: " .. table.concat(present, ", "))
	end)

	T.it("does not require removed word_game.config.gameplay round/economy paths", function()
		local stale = audit.stale_config_requires()
		T.assert_equal(#stale, 0, "stale requires: " .. table.concat(stale, ", "))
	end)
end)
