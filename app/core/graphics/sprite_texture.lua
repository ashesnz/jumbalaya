return function(GfxSprite)
local sprite_util = require("app.core.graphics.sprite_util")
--- Recomputes the projection scale after a resize.
function GfxSprite:refresh_scale()
	self.scale_mag = math.min(self.scale.x / self.T.w, self.scale.y / self.T.h)
end

--- Rebinds the atlas by name (after hot-reload / texture-scaling change).
function GfxSprite:reset()
	self.atlas = (G.TEXTURE_ATLASES and G.TEXTURE_ATLASES[self.atlas.name]) or self.atlas
	self:set_sprite_pos(self.sprite_pos)
end

--- Builds the source quad. `sprite_pos.v` picks a random variant row index.
function GfxSprite:set_sprite_pos(sprite_pos)
	if sprite_pos and sprite_pos.v then
		self.sprite_pos = {x = math.random(sprite_pos.v) - 1, y = sprite_pos.y}
	else
		self.sprite_pos = sprite_pos or {x = 0, y = 0}
	end
	self.sprite_pos_copy = {x = self.sprite_pos.x, y = self.sprite_pos.y}

	local img_w, img_h = sprite_util.atlas_dimensions(self.atlas)

	if love.graphics and love.graphics.newQuad then
		self.sprite = love.graphics.newQuad(
			self.sprite_pos.x * (self.atlas and self.atlas.px or 1),
			self.sprite_pos.y * (self.atlas and self.atlas.py or 1),
			self.scale.x,
			self.scale.y, img_w, img_h)
	end

	self.image_dims = {img_w, img_h}
end

--- Cell position + size fed to the `texture_details` shader uniform.
function GfxSprite:texture_descriptor()
	local descriptor = self.RETS.texture_descriptor or {}
	local position = self.sprite_pos or {x = 0, y = 0}
	local atlas = self.atlas or {}
	descriptor[1] = position.x
	descriptor[2] = position.y
	descriptor[3] = atlas.px or 1
	descriptor[4] = atlas.py or 1
	self.RETS.texture_descriptor = descriptor
	return descriptor
end

--- Full image size fed to the `image_details` shader uniform.
function GfxSprite:image_dimensions()
	return self.image_dims
end

--- Converts tile-space drawing into texel space for the current quad.
function GfxSprite:apply_texture_scale()
	love.graphics.scale(1 / (self.scale.x / self.VT.w), 1 / (self.scale.y / self.VT.h))
end

--- Draws the quad (or video frame) centered in the pushed transform.
function GfxSprite:draw_texture(overlay)
	love.graphics.setColor(overlay or G.OVERLAY_TINT or G.C.WHITE)

	if self.video then
		self.video_dims = self.video_dims or {
			w = self.video:getWidth(),
			h = self.video:getHeight(),
		}
		love.graphics.draw(
			self.video, 0, 0, 0,
			self.VT.w / self.T.w / (self.video_dims.w / self.scale.x),
			self.VT.h / self.T.h / (self.video_dims.h / self.scale.y))
		return
	end

	love.graphics.draw(
		self.atlas.image, self.sprite, 0, 0, 0,
		self.VT.w / self.T.w, self.VT.h / self.T.h)
end
end
