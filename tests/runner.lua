--[[ tests/runner.lua
     Test suite discoverer and runner.
]]

local M = {}

local function discover_test_modules()
	local modules = {}
	local handle = io.popen('ls -1 tests/unit/test_*.lua 2>/dev/null')
	if handle then
		for line in handle:lines() do
			local name = line:match('([^/]+)%.lua$')
			if name then
				modules[#modules + 1] = 'tests.unit.' .. name
			end
		end
		handle:close()
	end
	table.sort(modules)
	return modules
end

function M.run()
	package.path = "./?.lua;./?/init.lua;" .. package.path

	local MockEnv = require("tests.helpers.mock_env")
	MockEnv.ensure_engine_globals()

	local T = require("tests.framework")
	T.reset()

	print("Running Jumbalaya Unit Test Suite...")

	local test_files = discover_test_modules()

	for _, module_name in ipairs(test_files) do
		local ok, err = pcall(require, module_name)
		if not ok then
			print(string.format("Error loading %s: %s", module_name, tostring(err)))
		end
	end

	local success = T.summary()
	return success
end

return M
