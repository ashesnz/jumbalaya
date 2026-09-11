--[[ tests/unit/test_legacy_shims.lua - No re-export proxy files or stale shim paths ]]

local T = require("tests.framework")
local audit = require("tests.helpers.legacy_shim_audit")

T.describe("legacy shim purge", function()
	T.it("loads proxy detector for return-require shims", function()
		T.assert_true(audit.is_return_require_proxy('return require("jumbalaya_core.config.gameplay.round")'))
		T.assert_true(audit.is_return_require_proxy('return require("jumbalaya-engine.boot").install()'))
		T.assert_false(audit.is_return_require_proxy("local M = {}\nreturn M"))
	end)

	T.it("loads side-effect shim detector", function()
		local shim = 'require "jumbalaya-engine.util.number_format"\n\nreturn true'
		T.assert_true(audit.is_side_effect_shim(shim))
	end)

	T.it("does not keep deleted proxy files", function()
		local present = audit.forbidden_proxy_files_present()
		T.assert_equal(#present, 0, "proxy files remain: " .. table.concat(present, ", "))
	end)

	T.it("does not require removed proxy shim paths", function()
		local stale = audit.stale_proxy_requires()
		T.assert_equal(#stale, 0, "stale requires: " .. table.concat(stale, ", "))
	end)

	T.it("has no unauthorized return-require proxies under word_game/", function()
		local unauthorized = audit.unauthorized_proxy_files()
		T.assert_equal(#unauthorized, 0, "proxies: " .. table.concat(unauthorized, ", "))
	end)

	T.it("has no side-effect require shims under word_game/", function()
		local shims = audit.side_effect_shim_files()
		T.assert_equal(#shims, 0, "side-effect shims: " .. table.concat(shims, ", "))
	end)

	T.it("allows only bootstrap engine_boot return-require delegate", function()
		local proxies = audit.scan_return_require_proxies()
		local allowed = {}
		for _, rel in ipairs(proxies) do
			if rel == "app/bootstrap/engine_boot.lua" then
				allowed[#allowed + 1] = rel
			end
		end
		T.assert_equal(#proxies, #allowed, "unexpected proxies: " .. table.concat(proxies, ", "))
	end)
end)
