--[[ app/callbacks/controllers/dispatch_wrap.lua - Funcs handlers that also dispatch input actions ]]

local action_dispatch = require("app.input.action_dispatch")

local M = {}

function M.wrap(name, impl)
	return function(...)
		action_dispatch.dispatch_func(name)
		return impl(...)
	end
end

function M.wrap_with_extra(name, extra_fn, impl)
	return function(...)
		local extra = extra_fn and extra_fn(...)
		action_dispatch.dispatch_func(name, extra)
		return impl(...)
	end
end

return M
