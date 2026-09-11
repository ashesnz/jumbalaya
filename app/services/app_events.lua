--[[ app/services/app_events.lua - Phase 4b app-level action bus (settings, menu, overlays) ]]

local M = {}

local listeners = {}

function M.on(action_type, fn)
	listeners[action_type] = listeners[action_type] or {}
	listeners[action_type][#listeners[action_type] + 1] = fn
end

function M.emit(action)
	if not action or not action.type then return end
	local subs = listeners[action.type]
	if not subs then return end
	for _, fn in ipairs(subs) do
		fn(action)
	end
end

return M
