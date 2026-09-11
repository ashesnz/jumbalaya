--[[ tests/helpers/core_env.lua - Headless jumbalaya_core test bootstrap (no engine globals) ]]

local M = {}

function M.setup_package_path()
	package.path = "./packages/?.lua;./packages/?/init.lua;"
		.. "./?.lua;./?/init.lua;"
		.. package.path
end

return M
