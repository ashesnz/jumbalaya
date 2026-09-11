--[[ tests/unit/test_error_handler.lua - Crash mail destination and copy ]]

local T = require("tests.framework")
local mock_env = require("tests.helpers.mock_env")
local ErrorHandler = require("app.error_handler")

T.describe("error handler crash mail", function()
	mock_env.reset_game()

	T.it("targets support@jumbalaya.co and never an AWS collector", function()
		T.assert_equal(ErrorHandler.SUPPORT_EMAIL, "support@jumbalaya.co")
		local url = ErrorHandler.crash_mailto_url("foo.lua:12: boom")
		T.assert_true(url:find("^mailto:support@jumbalaya%.co%?", 1) ~= nil, url)
		T.assert_nil(url:find("amazonaws", 1, true), "must not mention AWS")
		T.assert_nil(url:find("execute%-api", 1), "must not use API Gateway")
		T.assert_true(url:find("Jumbalaya", 1, true) ~= nil)
	end)

	T.it("only opens mail when opted in on a release build", function()
		_G._RELEASE_MODE = false
		G.F_CRASH_REPORTS = true
		G.SETTINGS.crashreports = true
		T.assert_false(ErrorHandler.crash_reports_opted_in())

		_G._RELEASE_MODE = true
		G.SETTINGS.crashreports = false
		T.assert_false(ErrorHandler.crash_reports_opted_in())

		G.SETTINGS.crashreports = true
		G.F_CRASH_REPORTS = false
		T.assert_false(ErrorHandler.crash_reports_opted_in())

		G.F_CRASH_REPORTS = true
		T.assert_true(ErrorHandler.crash_reports_opted_in())
		_G._RELEASE_MODE = false
	end)

	T.it("tells the player to email support in the fallback UI", function()
		_G._RELEASE_MODE = true
		G.F_CRASH_REPORTS = true
		G.SETTINGS.crashreports = false
		local opted_out = ErrorHandler.player_error_message("boom", "trace")
		T.assert_true(opted_out:find("support@jumbalaya.co", 1, true) ~= nil)
		T.assert_nil(opted_out:find("a crash report was sent", 1, true))

		G.SETTINGS.crashreports = true
		local opted_in = ErrorHandler.player_error_message("boom", "trace")
		T.assert_true(opted_in:find("support@jumbalaya.co", 1, true) ~= nil)
		T.assert_true(opted_in:find("email app", 1, true) ~= nil)
		_G._RELEASE_MODE = false
	end)

	T.it("open_crash_mail uses love.system.openURL with the mailto URL", function()
		local opened
		love.system = love.system or {}
		local prev = love.system.openURL
		love.system.openURL = function(url)
			opened = url
		end
		local url = ErrorHandler.open_crash_mail("tests/unit/test_error_handler.lua:1: example")
		T.assert_equal(opened, url)
		T.assert_true(url:find("mailto:support@jumbalaya.co", 1, true) ~= nil)
		love.system.openURL = prev
	end)
end)
