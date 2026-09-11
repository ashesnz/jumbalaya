--[[
	jumbalaya-engine/input.lua - InputService interface and Love2D adapter.
]]

---@class InputService
local InputService = {}
InputService.__index = InputService

function InputService.new(store)
	return setmetatable({ _store = store }, InputService)
end

function InputService:on_pointer_down(x, y)
	return { hit = false, x = x, y = y }
end

function InputService:on_action(action)
	if self._store and self._store.dispatch then
		self._store:dispatch(action)
	end
end

return InputService
