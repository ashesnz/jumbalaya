--[[ app/core/graphics/sprite_animator.lua - strip-frame animation (GfxAnimator) ]]

GfxAnimator = GfxSprite:derive("GfxAnimator")
SpriteAnimator = GfxAnimator

function GfxAnimator:construct(X, Y, W, H, new_sprite_atlas, sprite_pos)
	GfxSprite.construct(self, X, Y, W, H, new_sprite_atlas, sprite_pos)
	self.offset = {x = 0, y = 0}
	self.animation_clock = G.TIMERS.REAL

	-- Unlike plain sprites, animators always join both registries.
	G.ANIMATIONS = G.ANIMATIONS or {}
	G.LIVE = G.LIVE or {}
	G.LIVE.SPRITE = G.LIVE.SPRITE or {}
	table.insert(G.ANIMATIONS, self)
	table.insert(G.LIVE.SPRITE, self)
end

function GfxAnimator:rescale()
	self:refresh_scale()
end

function GfxAnimator:reset()
	self.atlas = (G.ANIM_SHEETS and G.ANIM_SHEETS[self.atlas.name]) or self.atlas
	self:configure_frames(self.animation.x, self.animation.y)
end

function GfxAnimator:configure_frames(column, row)
	local atlas = self.atlas
	local frame_count = math.max(1, math.floor(tonumber(atlas.frames) or 1))
	local width, height = self.scale.x, self.scale.y
	local image_width, image_height = atlas.image:getDimensions()

	self.animation = {
		x = column or 0, y = row or 0,
		frames = frame_count, current = 0,
		w = width, h = height,
	}
	self.sprite_pos = {x = self.animation.x, y = self.animation.y}
	self.sprite_pos_copy = {x = self.animation.x, y = self.animation.y}
	self.current_animation = {
		current = 0,
		frames = self.animation.frames,
		w = self.animation.w,
		h = self.animation.h,
	}
	self.image_dims = {image_width, image_height}
	self.sprite = love.graphics.newQuad(
		0, height * self.animation.y, width, height, image_width, image_height)
	self.animation_clock = G.TIMERS.REAL
end

function GfxAnimator:texture_descriptor()
	local descriptor = self.RETS.texture_descriptor or {}
	descriptor[1] = self.current_animation.current
	descriptor[2] = self.animation.y
	descriptor[3] = self.animation.w
	descriptor[4] = self.animation.h
	self.RETS.texture_descriptor = descriptor
	return descriptor
end

function GfxAnimator:set_sprite_pos(sprite_pos)
	self:configure_frames(sprite_pos and sprite_pos.x, sprite_pos and sprite_pos.y)
end

function GfxAnimator:frame_at_time(elapsed, rate, frame_count)
	if frame_count <= 1 then return 0 end
	return math.floor(math.max(0, elapsed) * math.max(0, rate) + 0.5) % frame_count
end

function GfxAnimator:set_frame_viewport(frame)
	self.frame_offset = frame * self.animation.w
	self.sprite:setViewport(
		self.frame_offset,
		self.animation.h * self.animation.y,
		self.animation.w,
		self.animation.h)
end

function GfxAnimator:advance_frame()
	local elapsed = math.max(0, G.TIMERS.REAL - self.animation_clock)
	local rate = math.max(0, tonumber(G.ANIMATION_FPS) or 0)
	local new_frame = self:frame_at_time(elapsed, rate, self.current_animation.frames)
	if new_frame ~= self.current_animation.current then
		self.current_animation.current = new_frame
		self:set_frame_viewport(new_frame)
	end
end

function GfxAnimator:update_float_motion(now)
	if not self.float then return end
	local parallax = self.shadow_parallax or {x = 0, y = 0}
	self.T.r = 0.018 * math.sin(now * 1.7 + self.T.x)
	self.offset.x = -(0.8 + 0.15 * math.sin(now * 0.55 + self.T.x)) * parallax.x
	self.offset.y = -(1 + 0.25 * math.sin(now * 0.55 + self.T.y)) * parallax.y
end

function GfxAnimator:animate()
	local now = G.TIMERS.REAL
	self:advance_frame()
	self:update_float_motion(now)
end

return GfxAnimator
