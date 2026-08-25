return function(GfxSprite)
local sprite_util = require("app.core.graphics.sprite_util")
--- Draws just this quad into the current (possibly shader-bound) pass.
function GfxSprite:draw_self(overlay)
	if not self.states.visible then return end

	-- Rebuild the quad if the position changed without a set_sprite_pos call.
	if self.sprite_pos.x ~= self.sprite_pos_copy.x or self.sprite_pos.y ~= self.sprite_pos_copy.y then
		self:set_sprite_pos(self.sprite_pos)
	end

	push_node_transform(self, 1)
	self:apply_texture_scale()
	self:draw_texture(overlay)
	love.graphics.pop()
	track_hit_target(self)
	self:draw_boundingrect()
	if self.shader_tab then love.graphics.setShader() end
end

--- Full draw: run configured shader passes (if any) or a plain draw, hash for
--- hit-testing around children, then draw children (hover popups excluded;
--- they are drawn last by the main loop).
function GfxSprite:draw(overlay)
	if not self.states.visible then return end

	if self.draw_steps then
		for _, step in ipairs(self.draw_steps) do
			self:apply_shader_effect(step.shader, step.shadow_height, step.send, step.no_tilt,
				step.other_obj, step.ms, step.mr, step.mx, step.my, not not step.send)
		end
	else
		self:draw_self(overlay)
	end

	track_hit_target(self)
	for k, v in pairs(self.children) do
		if k ~= 'h_popup' then v:draw() end
	end
	track_hit_target(self)
	self:draw_boundingrect()
end

--- Scale factor that projects our texels onto another object's transform.
function GfxSprite:projection_scale(target)
	return 1 / (target.scale_mag or target.VT.scale or 1)
end

--- Horizontal correction keeping projections centered on the target.
function GfxSprite:projection_offset(target)
	return -(target.T.w / 2 - target.VT.w / 2) * 10
end

function GfxSprite:draw_projected_texture(target)
	love.graphics.scale(self:projection_scale(target))
	love.graphics.setColor(G.OVERLAY_TINT or G.C.WHITE)
	love.graphics.draw(
		self.atlas.image, self.sprite,
		self:projection_offset(target), 0, 0,
		target.VT.w / target.T.w, target.VT.h / target.T.h)
	self:draw_boundingrect()
end

--- Draws this texture using another object's transform (holographic overlays).
--  The transform stack stays balanced even if drawing fails mid-way.
function GfxSprite:project_onto(other_obj, ms, mr, mx, my)
	self.ARGS.draw_from_offset = self.ARGS.draw_from_offset or {}
	self.ARGS.draw_from_offset.x = mx or 0
	self.ARGS.draw_from_offset.y = my or 0

	local ok, err = pcall(function()
		push_node_transform(other_obj, 1 + (ms or 0), mr or 0, self.ARGS.draw_from_offset, true)
		self:draw_projected_texture(other_obj)
	end)
	love.graphics.pop()
	if not ok then error(err, 0) end
end

function GfxSprite:remove()
	if self.video then self.video:release() end
	sprite_util.unregister_instance(G.ANIMATIONS, self)
	sprite_util.unregister_instance(G.LIVE and G.LIVE.SPRITE, self)
	AnimNode.remove(self)
end
end
