--[[ word_game/ui/perks/shared/voucher_sprite.lua - Moveable perk voucher for UI/market ]]

local perk_voucher = require("word_game.ui.perks.shared.voucher")
local NodeTransform = require("jumbalaya-engine.graphics.node_transform")
local HitOrder = require("jumbalaya-engine.graphics.hit_order")

PerkVoucherSprite = AnimNode:derive("PerkVoucherSprite")

function PerkVoucherSprite:construct(X, Y, W, H, entry)
	AnimNode.construct(self, X, Y, W, H)
	self.CT = self.VT
	self.entry = entry
	self.states.drag.can = false
	self.states.hover.can = false
	self.states.collide.can = false
	self.states.click.can = false
end

function PerkVoucherSprite:draw_self()
	if not self.states.visible or not self.entry then return end
	NodeTransform.push_node_transform(self, 1)
	perk_voucher.draw(self.entry, 0, 0, self.VT.w, self.VT.h, 1)
	love.graphics.pop()
	HitOrder.track_hit_target(self)
	self:draw_boundingrect()
end

function PerkVoucherSprite:draw()
	if not self.states.visible then return end
	self:draw_self()
	for k, v in pairs(self.children) do
		if k ~= "h_popup" then v:draw() end
	end
end

return PerkVoucherSprite
