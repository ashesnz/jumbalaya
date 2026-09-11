--[[ app/callbacks/run_lifecycle.lua - Run start / menu return FUNCS registration ]]

local action_dispatch = require("app.input.action_dispatch")
local RunLifecycle = require("app.controllers.run_lifecycle")
local Funcs = require("app.callbacks.funcs")

Funcs.register("notify_then_start_run", function(e)
	RunLifecycle.notify_then_start_run(e)
end)

Funcs.register("begin_run", function(e, args)
	action_dispatch.dispatch_func("begin_run", args and { run_mode = args.run_mode })
	RunLifecycle.begin_run(e, args)
end)

Funcs.register("begin_classic_run", function(e)
	action_dispatch.dispatch_func("begin_classic_run")
	RunLifecycle.begin_classic_run(e)
end)

Funcs.register("begin_time_run", function(e)
	action_dispatch.dispatch_func("begin_time_run")
	RunLifecycle.begin_time_run(e)
end)

Funcs.register("return_to_menu", function(e)
	action_dispatch.dispatch_func("return_to_menu")
	RunLifecycle.return_to_menu(e)
end)
