--[[ app/core/scene/node.lua - transform tree node with interaction state ]]

local Kind = require("app.core.object")

---@class Node : Kind
Node = Kind:derive("Node")

function Node:construct(args)
	args = args or {}
	args.T = args.T or {}

	self.ARGS = self.ARGS or {}
	self.RETS = {}
	self.config = self.config or {}

	self.T = {
		x = args.T.x or args.T[1] or 0,
		y = args.T.y or args.T[2] or 0,
		w = args.T.w or args.T[3] or 1,
		h = args.T.h or args.T[4] or 1,
		r = args.T.r or args.T[5] or 0,
		scale = args.T.scale or args.T[6] or 1,
	}
	self.CT = self.T
	self.click_offset = { x = 0, y = 0 }
	self.hover_offset = { x = 0, y = 0 }
	self.created_on_pause = G.SETTINGS.paused
	self.REMOVED = false

	G.ID = G.ID or 1
	self.ID = G.ID
	G.ID = G.ID + 1

	self.FRAME = { RENDER = -1, TRANSFORM = -1 }
	self.states = {
		visible = true,
		collide = { can = false, is = false },
		focus = { can = false, is = false },
		hover = { can = true, is = false },
		click = { can = true, is = false },
		drag = { can = true, is = false },
		release_on = { can = true, is = false },
	}

	self.container = args.container or G.ROOM
	self.children = self.children or {}

	if getmetatable(self) == Node then
		table.insert(G.LIVE.NODE, self)
	end
	if not G.STAGE_OBJECT_INTERRUPT then
		table.insert(G.STAGE_OBJECTS[G.STAGE], self)
	end
end

require("app.core.scene.node_debug")(Node)
require("app.core.scene.node_hit")(Node)
require("app.core.scene.node_lifecycle")(Node)

SceneNode = Node

return Node
