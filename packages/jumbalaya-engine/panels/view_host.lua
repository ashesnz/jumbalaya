--[[ jumbalaya-engine/panels/view_host.lua - Thin wrapper around a panel instance ]]

local Panel = require("jumbalaya-engine.panels.panel")
require("jumbalaya-engine.panels.container")

local ViewHost = {}
ViewHost.__index = ViewHost

local function delegate_index(view, key)
	local method = rawget(ViewHost, key)
	if method ~= nil then
		return method
	end
	local own = rawget(view, key)
	if own ~= nil then
		return own
	end
	local inner = rawget(view, "_inner")
	while inner ~= nil and inner ~= view do
		local inner_own = rawget(inner, key)
		if inner_own ~= nil then
			return inner_own
		end
		local mt = getmetatable(inner)
		local idx = mt and mt.__index
		if idx == delegate_index then
			inner = rawget(inner, "_inner")
		elseif type(idx) == "table" then
			return idx[key]
		elseif type(idx) == "function" then
			return idx(inner, key)
		else
			return nil
		end
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

--- Create a ViewHost with the same constructor table as Panel.
function ViewHost.create(args)
	return ViewHost.wrap(Panel(args))
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
