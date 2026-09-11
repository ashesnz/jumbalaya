--[[
	jumbalaya-engine/event_bus.lua - Thin pub/sub for presentation events (Phase 6).
]]

---@class EventBus
local EventBus = {}
EventBus.__index = EventBus

function EventBus.new()
	return setmetatable({ _listeners = {} }, EventBus)
end

function EventBus:on(event, fn)
	local list = self._listeners[event]
	if not list then
		list = {}
		self._listeners[event] = list
	end
	list[#list + 1] = fn
end

function EventBus:emit(event, ...)
	local list = self._listeners[event]
	if not list then return end
	for _, fn in ipairs(list) do
		fn(...)
	end
end

function EventBus:clear(event)
	if event then
		self._listeners[event] = nil
	else
		self._listeners = {}
	end
end

return EventBus
