--[[
	jumbalaya-engine/scene/roots.lua - Dense scene root list for draw pass.

	Root nodes (no parent, live in LIVE.NODE or LIVE.TRANSFORM) are tracked here
	so render_scene_pass avoids pairs() over sparse LIVE tables every frame.
]]

local shell = require("jumbalaya-engine.shell")
local Tables = require("jumbalaya-engine.util.tables")

local M = {}

local function game()
	return shell.game()
end

local function roots()
	local g = game()
	if not g then return {} end
	g.SCENE_ROOTS = g.SCENE_ROOTS or {}
	return g.SCENE_ROOTS
end

local function qualifies(node)
	if not node or node.REMOVED then return false end
	if not node._live_registry then return false end
	if node.parent then return false end
	if node.states and node.states.visible == false then return false end
	return true
end

function M.register(node, registry_kind)
	if not node then return end
	node._live_registry = registry_kind
	M.sync(node)
end

function M.unregister(node)
	if not node then return end
	Tables.remove_swap_last(roots(), node)
	node._live_registry = nil
end

function M.set_parent(node, parent)
	if not node or node.parent == parent then return end
	node.parent = parent
	M.sync(node)
end

function M.sync(node)
	if qualifies(node) then
		local list = roots()
		for _, entry in ipairs(list) do
			if entry == node then return end
		end
		list[#list + 1] = node
	else
		Tables.remove_swap_last(roots(), node)
	end
end

function M.each()
	return ipairs(roots())
end

return M
