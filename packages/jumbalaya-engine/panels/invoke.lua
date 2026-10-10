--[[ jumbalaya-engine/panels/invoke.lua - Function or string panel callbacks ]]

local shell = require("jumbalaya-engine.shell")

local M = {}

--- Invoke a panel handler. Functions are called directly; strings go through
--- the Funcs catalog when still registered (unmigrated screens).
function M.call(handler, ...)
	local kind = type(handler)
	if kind == "function" then
		return handler(...)
	end
	if kind == "string" and shell.get_func(handler) then
		return shell.dispatch_func(handler, ...)
	end
end

return M
