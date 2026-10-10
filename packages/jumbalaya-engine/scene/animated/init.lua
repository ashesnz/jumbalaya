--[[ jumbalaya-engine/scene/animated/init.lua - Spatial: drawn springs toward target ]]

local Node = require("jumbalaya-engine.scene.node")
local SceneRoots = require("jumbalaya-engine.scene.roots")
local Tables = require("jumbalaya-engine.util.tables")
local DropShadow = require("jumbalaya-engine.graphics.drop_shadow")

local shell = require("jumbalaya-engine.shell")
local game = shell.game

---@class AnimNode : Node
local AnimNode = Node:derive("AnimNode")

require("jumbalaya-engine.scene.animated.alignment")(AnimNode)
require("jumbalaya-engine.scene.animated.transform")(AnimNode)
require("jumbalaya-engine.scene.animated.bounce")(AnimNode)
require("jumbalaya-engine.scene.animated.integrate")(AnimNode)
require("jumbalaya-engine.scene.animated.attach")(AnimNode)
require("jumbalaya-engine.scene.animated.motion")(AnimNode)

function AnimNode:construct(X, Y, W, H)
	local args = (type(X) == "table") and X or { T = { X or 0, Y or 0, W or 0, H or 0 } }
	Node.construct(self, args)

	self.target = self.T
	self.drawn = {
		x = self.T.x, y = self.T.y,
		w = self.T.w, h = self.T.h,
		r = self.T.r, scale = self.T.scale,
	}
	self.VT = self.drawn
	self.velocity = { x = 0, y = 0, r = 0, scale = 0, mag = 0 }
	self.attach = {
		mode = "independent",
		host = nil,
		offset = { x = 0, y = 0 },
		draw_host = self,
		lock_drawn = false,
		dirty = false,
	}
	self.alignment = {
		type = "a",
		offset = { x = 0, y = 0 },
		prev_type = "",
		prev_offset = { x = 0, y = 0 },
	}
	self.pinch = { x = false, y = false }
	self.last_moved = -1
	self.last_aligned = -1
	self.static_rotation = false
	self.offset = { x = 0, y = 0 }
	self.Mid = self
	self.shadow_parallax = { x = DropShadow.X, y = DropShadow.Y }
	self.parallax_shift = { x = 0, y = 0 }
	self.shadow_height = 0.2
	self.settled = true
	self.STATIONARY = true

	table.insert(game().TRANSFORMS, self)
	table.insert(game().LIVE.TRANSFORM, self)
	SceneRoots.register(self, "transform")
end

function AnimNode:draw()
	Node.draw(self)
	self:draw_boundingrect()
end

function AnimNode:remove()
	SceneRoots.unregister(self)
	Tables.remove_swap_last(game().TRANSFORMS, self)
	Tables.remove_swap_last(game().LIVE.TRANSFORM, self)
	Node.remove(self)
end

return AnimNode
