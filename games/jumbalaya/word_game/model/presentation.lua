--[[
	word_game/model/presentation.lua - Model→UI event bus (contract: types/presentation.lua).

	Core: none (glue only)
	Store: none — listeners read game_access.get() in ui/presentation/install.lua
	Presentation: emit(event, …) fans out to registered UI handlers at boot
]]

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
