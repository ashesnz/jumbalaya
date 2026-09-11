--[[ packages/jumbalaya_core/store/init.lua - Engine-agnostic run state container ]]

local default_state = require("jumbalaya_core.store.default_state")
local reducers = require("jumbalaya_core.store.reducers")

local M = {}
M.__index = M

function M.new(initial)
	return setmetatable({
		_state = initial or default_state.new(),
		_subscribers = {},
	}, M)
end

function M.default_state()
	return default_state.new()
end

function M:get()
	return self._state
end

function M:replace(state)
	self._state = state
	self:_notify()
end

function M:patch(patch)
	for key, value in pairs(patch) do
		self._state[key] = value
	end
	self:_notify()
end

function M:subscribe(fn)
	self._subscribers[#self._subscribers + 1] = fn
end

function M:dispatch(action)
	self._state = reducers.reduce(self._state, action)
	self:_notify()
	return self._state
end

function M:_notify()
	for _, fn in ipairs(self._subscribers) do
		fn(self._state)
	end
end

return M
