--[[
	bridge/funcs_registry.lua - UIBox string callback registry (Phase 9e).

	Handlers are module-scoped; retained UI dispatches via Funcs.dispatch(name, ...).
	Catalog for analyzers: types/funcs.lua
]]

local M = {}

local handlers = {}

function M.register(name, fn)
	handlers[name] = fn
end

function M.unregister(name)
	handlers[name] = nil
end

function M.get(name)
	return handlers[name]
end

function M.dispatch(name, ...)
	local fn = handlers[name]
	if fn then
		return fn(...)
	end
end

---@deprecated kept for callers that still invoke install after define_constants
function M.install(_game) end

return M
