--[[ tests/runner.lua
     Test suite discoverer and runner.
]]

local M = {}

local function discover_test_modules()
	local modules = {}
	local files
	for _, dir in ipairs({ "tests/unit", "unit", "games/jumbalaya/tests/unit" }) do
		local listing = love.filesystem.getDirectoryItems(dir)
		if listing and #listing > 0 then
			files = listing
			break
		end
	end
	files = files or {}
	for _, name in ipairs(files) do
		if name:match("^test_.*%.lua$") then
			modules[#modules + 1] = "tests.unit." .. name:sub(1, -5)
		end
	end
	table.sort(modules)
	return modules
end

function M.run()
	require("bootstrap_paths").install()

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
