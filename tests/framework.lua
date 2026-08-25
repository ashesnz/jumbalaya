--[[ tests/framework.lua
     Minimalist unit test harness for Jumbalaya.
]]

local M = {}

local current_suite = ""
local passed_count = 0
local failed_count = 0
local errors = {}

function M.describe(suite_name, fn)
	current_suite = suite_name
	print(string.format("\n=== %s ===", suite_name))
	local ok, err = pcall(fn)
	if not ok then
		failed_count = failed_count + 1
		local err_msg = string.format("[%s] Suite crashed: %s", suite_name, tostring(err))
		table.insert(errors, err_msg)
		print("  FAIL (suite crash): " .. tostring(err))
	end
end

function M.it(test_name, fn)
	local full_name = current_suite .. " -> " .. test_name
	local ok, err = pcall(fn)
	if ok then
		passed_count = passed_count + 1
		print(string.format("  ✓ %s", test_name))
	else
		failed_count = failed_count + 1
		local err_msg = string.format("[%s] %s\n    %s", current_suite, test_name, tostring(err))
		table.insert(errors, err_msg)
		print(string.format("  ✗ %s\n    Error: %s", test_name, tostring(err)))
	end
end

M.test = M.it

function M.assert_true(cond, msg)
	if not cond then
		error(msg or "Expected condition to be true, got false/nil", 2)
	end
end

function M.assert_false(cond, msg)
	if cond then
		error(msg or "Expected condition to be false, got truthy", 2)
	end
end

function M.assert_equal(actual, expected, msg)
	if actual ~= expected then
		error(string.format("%s (expected %s, got %s)", msg or "Assertion failed", tostring(expected), tostring(actual)), 2)
	end
end

function M.assert_not_equal(actual, expected, msg)
	if actual == expected then
		error(string.format("%s (expected not %s, got %s)", msg or "Assertion failed", tostring(expected), tostring(actual)), 2)
	end
end

function M.assert_nil(val, msg)
	if val ~= nil then
		error(string.format("%s (expected nil, got %s)", msg or "Assertion failed", tostring(val)), 2)
	end
end

function M.assert_not_nil(val, msg)
	if val == nil then
		error(msg or "Expected non-nil value, got nil", 2)
	end
end

function M.assert_almost_equal(actual, expected, eps, msg)
	eps = eps or 0.0001
	if math.abs(actual - expected) > eps then
		error(string.format("%s (expected ~%f, got %f, diff=%f > %f)", msg or "Assertion failed", expected, actual, math.abs(actual - expected), eps), 2)
	end
end

function M.summary()
	print("\n==========================================")
	print(string.format("Test Results: %d passed, %d failed (Total: %d)", passed_count, failed_count, passed_count + failed_count))
	if #errors > 0 then
		print("\nFailures:")
		for i, err in ipairs(errors) do
			print(string.format("%d) %s", i, err))
		end
		print("==========================================")
		return false
	else
		print("All tests passed successfully!")
		print("==========================================")
		return true
	end
end

function M.reset()
	passed_count = 0
	failed_count = 0
	errors = {}
	current_suite = ""
end

return M
