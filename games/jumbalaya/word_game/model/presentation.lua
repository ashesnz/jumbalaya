--[[ word_game/model/presentation.lua - UI reaction hooks registered at boot (see types/presentation.lua) ]]

---@type Presentation
local M = {
	_listeners = {},
	_event_bus = nil,
}

function M.on(event, fn)
	M._listeners[event] = fn
end

function M.bind_events(bus)
	M._event_bus = bus
end

function M.emit(event, ...)
	local fn = M._listeners[event]
	local result
	if fn then
		result = fn(...)
	end
	if M._event_bus and M._event_bus.emit then
		M._event_bus:emit(event, ...)
	end
	return result
end

function M.clear()
	M._listeners = {}
end

return M
