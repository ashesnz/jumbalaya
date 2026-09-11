--[[ jumbalaya-engine/interaction/action_bridge.lua - router → typed action dispatch ]]

local shell = require("jumbalaya-engine.shell")

local M = {}

function M.dispatch(action)
	shell.dispatch_action(action)
end

function M.dispatch_func(name, extra)
	return shell.dispatch_action_func(name, extra)
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
