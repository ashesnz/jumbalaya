--[[ app/core/scene/animated/init.lua - eased visible transform (VT follows T) ]]

local Node = require("app.core.scene.node")

---@class AnimNode : Node
AnimNode = Node:derive("AnimNode")
EaseNode = AnimNode

require("app.core.scene.animated.alignment")(AnimNode)
require("app.core.scene.animated.transform")(AnimNode)
require("app.core.scene.animated.bounce")(AnimNode)
require("app.core.scene.animated.motion")(AnimNode)
require("app.core.scene.animated.integrate")(AnimNode)
require("app.core.scene.animated.role")(AnimNode)

function AnimNode:construct(X, Y, W, H)
	local args = (type(X) == "table") and X or { T = { X or 0, Y or 0, W or 0, H or 0 } }
	Node.construct(self, args)

	self.VT = {
		x = self.T.x, y = self.T.y,
		w = self.T.w, h = self.T.h,
		r = self.T.r, scale = self.T.scale,
	}
	self.velocity = { x = 0, y = 0, r = 0, scale = 0, mag = 0 }
	self.role = {
		role_type = "Major",
		offset = { x = 0, y = 0 },
		major = nil,
		draw_major = self,
		xy_bond = "Strong",
		wh_bond = "Strong",
		r_bond = "Strong",
		scale_bond = "Strong",
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
	self.shadow_parallax = { x = 0, y = -1.8 }
	self.parallax_shift = { x = 0, y = 0 }
	self.shadow_height = 0.2
	self:calculate_parallax()

	table.insert(G.TRANSFORMS, self)
	if getmetatable(self) == AnimNode then
		table.insert(G.LIVE.TRANSFORM, self)
	end
end

function AnimNode:draw()
	Node.draw(self)
	self:draw_boundingrect()
end

function AnimNode:remove()
	for _, registry in ipairs({ G.TRANSFORMS, G.LIVE.TRANSFORM }) do
		for k, v in ipairs(registry) do
			if v == self then
				table.remove(registry, k)
				break
			end
		end
	end
	Node.remove(self)
end

return AnimNode
