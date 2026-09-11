--[[
	jumbalaya-engine/view_host.lua - Generic retained-panel host for Phase 8 migration.
]]

local RetainedUI = require("jumbalaya-engine.retained_ui")

local ViewHost = {}
ViewHost.__index = ViewHost

local function delegate_index(view, key)
	if ViewHost[key] ~= nil then
		return ViewHost[key]
	end
	local own = rawget(view, key)
	if own ~= nil then
		return own
	end
	local inner = view._inner
	if inner then
		return inner[key]
	end
	return nil
end

function ViewHost.wrap(inner)
	local view = setmetatable({
		_inner = inner,
	}, ViewHost)
	setmetatable(view, { __index = function(t, k) return delegate_index(t, k) end })
	view.T = inner.T
	view.VT = inner.VT
	view.root_node = inner.root_node
	view.config = inner.config
	view.REMOVED = inner.REMOVED
	view.children = inner.children
	return view
end

--- Create a ViewHost with the same constructor table as RetainedPanel.
function ViewHost.create(args)
	return ViewHost.wrap(RetainedUI.create(args))
end

function ViewHost:draw()
	if self._inner then
		self._inner:draw()
	end
end

function ViewHost:recalculate()
	if not self._inner then return end
	self._inner:recalculate()
	self.T = self._inner.T
	self.VT = self._inner.VT
	self.root_node = self._inner.root_node
	self.config = self._inner.config
	self.REMOVED = self._inner.REMOVED
	self.children = self._inner.children
end

function ViewHost:remove()
	if self._inner and self._inner.remove then
		self._inner:remove()
	end
	self._inner = nil
	self.REMOVED = true
end

function ViewHost:find_node_by_id(id)
	if self._inner and self._inner.find_node_by_id then
		return self._inner:find_node_by_id(id)
	end
	return nil
end

return ViewHost
