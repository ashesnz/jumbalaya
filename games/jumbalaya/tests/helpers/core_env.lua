--[[ tests/helpers/core_env.lua - Headless jumbalaya_core test bootstrap (no engine globals) ]]

local M = {}

function M.setup_package_path()
	if not package.loaded["bootstrap_paths"] then
		require("bootstrap_paths").install()
	end
end

return M
