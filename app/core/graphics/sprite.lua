--[[ app/core/graphics/sprite.lua - textured atlas quad (GfxSprite) ]]

GfxSprite = AnimNode:derive("GfxSprite")
Sprite = GfxSprite

function GfxSprite:construct(X, Y, W, H, new_sprite_atlas, sprite_pos)
	AnimNode.construct(self, X, Y, W, H)
	self.CT = self.VT -- collision follows the visible quad
	self.atlas = new_sprite_atlas

	-- Placeholder atlas: nothing to sample yet; stay invisible until reset().
	if not self.atlas or not self.atlas.px then
		self.atlas = {px = 1, py = 1, image = nil, name = ""}
		self.scale = {x = 1, y = 1}
		self.scale_mag = 1
		self.zoom = true
		self.sprite_pos = sprite_pos or {x = 0, y = 0}
		self.states.visible = false
		if getmetatable(self) == GfxSprite then table.insert(G.LIVE.SPRITE, self) end
		return
	end

	self.scale = {x = self.atlas.px, y = self.atlas.py}
	self.scale_mag = math.min(self.scale.x / W, self.scale.y / H)
	self.zoom = true

	self:set_sprite_pos(sprite_pos)

	if getmetatable(self) == GfxSprite then table.insert(G.LIVE.SPRITE, self) end
end

require("app.core.graphics.sprite_texture")(GfxSprite)
require("app.core.graphics.sprite_shader")(GfxSprite)
require("app.core.graphics.sprite_draw")(GfxSprite)

return GfxSprite
