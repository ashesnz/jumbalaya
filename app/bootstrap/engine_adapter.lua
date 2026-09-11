--[[ app/bootstrap/engine_adapter.lua - Phase 7 Love2D lifecycle and boot orchestration ]]

local M = {}

function M.install()
	require "app.bootstrap.engine_boot"
	require "app.bootstrap.runtime_boot"
	require("app.bootstrap.store_boot").install()
	require("app.bootstrap.presentation_boot").install()
end

return M
