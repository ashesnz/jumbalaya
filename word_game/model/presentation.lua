--[[ word_game/model/presentation.lua - UI reaction hooks registered at boot (see types/presentation.lua) ]]

---@type Presentation
local M = {
	_listeners = {},
}

function M.on(event, fn)
	M._listeners[event] = fn
end

function M.emit(event, ...)
	local fn = M._listeners[event]
	if fn then
		return fn(...)
	end
end

function M.clear()
	M._listeners = {}
end

return M
