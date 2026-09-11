--[[ app/core/input/action_bridge.lua - Phase 4 router → typed action dispatch ]]
local BridgeRuntime = require("app.runtime")
local function g() return BridgeRuntime.game() end


local action_dispatch = require("app.input.action_dispatch")

local M = {}

function M.dispatch(action)
	action_dispatch.dispatch(action)
end

function M.dispatch_func(name, extra)
	return action_dispatch.dispatch_func(name, extra)
end

function M.attach_router(router)
	if not router then return end
	router.dispatch_action = function(action)
		return M.dispatch(action)
	end
	router.dispatch_func = function(name, extra)
		return M.dispatch_func(name, extra)
	end
end

return M
