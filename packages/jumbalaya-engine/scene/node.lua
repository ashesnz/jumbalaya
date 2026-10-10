--[[ jumbalaya-engine/scene/node.lua - SceneNode: identity, children, input flags ]]

local Kind = require("jumbalaya-engine.object")
local InputFlags = require("jumbalaya-engine.scene.input_flags")

local shell = require("jumbalaya-engine.shell")
local game = shell.game
local SceneRoots = require("jumbalaya-engine.scene.roots")

---@class Node : Kind
local Node = Kind:derive("Node")

function Node:construct(args)
	args = args or {}
	local rect = args.T or args.rect or args
	if type(rect) ~= "table" then rect = {} end

	self.config = self.config or {}

	self.target = {
		x = rect.x or rect[1] or 0,
		y = rect.y or rect[2] or 0,
		w = rect.w or rect[3] or 1,
		h = rect.h or rect[4] or 1,
		r = rect.r or rect[5] or 0,
		scale = rect.scale or rect[6] or 1,
	}
	self.T = self.target
	self.click_offset = { x = 0, y = 0 }
	self.hover_offset = { x = 0, y = 0 }
	self.moves_while_paused = game().SETTINGS.paused
	self.REMOVED = false

	game().ID = game().ID or 1
	self.ID = game().ID
	game().ID = game().ID + 1

	self.FRAME = { RENDER = -1, TRANSFORM = -1 }
	self.states = InputFlags.new()

	-- `container` is the room coordinate root (screen-shake space). Scene
	-- parent is a separate graph (`set_scene_parent`); hit/drag walk to ROOM.
	self.container = args.container or game().ROOM
	self.children = self.children or {}

	if getmetatable(self) == Node then
		table.insert(game().LIVE.NODE, self)
		SceneRoots.register(self, "node")
	end
	if not game().STAGE_OBJECT_INTERRUPT then
		table.insert(game().STAGE_OBJECTS[game().STAGE], self)
	end
end

--- Room is the coordinate-space root (screen-shake). Scene `parent` is not
--- a local transform parent — node `target` is already in room space.
function Node:coord_root()
	return game().ROOM or self.container or self
end

require("jumbalaya-engine.scene.node_debug")(Node)
require("jumbalaya-engine.scene.node_hit")(Node)
require("jumbalaya-engine.scene.node_lifecycle")(Node)

return Node
