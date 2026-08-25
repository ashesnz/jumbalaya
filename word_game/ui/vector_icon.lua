--[[
	word_game/ui/vector_icon.lua - tiny drawable node for vector UI icons.

	Wraps a draw callback in an AnimNode so UI trees can embed resolution-
	independent icons ({n=G.UI.OBJECT, config={object=...}}) that stay crisp
	at any scale and always match surrounding font metrics.
]]

local Node = require("app.core.scene.node")

---@class VectorIcon : AnimNode
local VectorIcon = AnimNode:derive("VectorIcon")

--- @param w number world-unit width
--- @param h number world-unit height
--- @param draw_fn fun(w: number, h: number) draws centred on (w/2, h/2)
function VectorIcon:construct(w, h, draw_fn)
	AnimNode.construct(self, 0, 0, w, h)
	self.icon_draw = draw_fn

	-- Purely decorative; never interact.
	self.states.hover.can = false
	self.states.click.can = false
	self.states.collide.can = false
	self.states.drag.can = false
	self.states.release_on.can = false
end

function VectorIcon:draw(alpha)
	push_node_transform(self, alpha or 1)
	love.graphics.translate(self.T.w / 2, self.T.h / 2)
	if self.icon_draw then self.icon_draw(self.T.w, self.T.h) end
	love.graphics.pop()

	track_hit_target(self)
	self:draw_boundingrect()
end

return VectorIcon
