return function(GfxSprite)
local sprite_util = require("app.core.graphics.sprite_util")
--- Replaces the render pipeline with an ordered list of shader passes.
--- Each step: `{shader=, shadow_height=, send={{name=, val=|func=|ref_table=+ref_value=}}, no_tilt=, other_obj=, ms, mr, mx, my}`
function GfxSprite:define_draw_steps(draw_step_definitions)
	self.draw_steps = clear_table(self.draw_steps)
	for _, definition in ipairs(draw_step_definitions) do
		self.draw_steps[#self.draw_steps + 1] = {
			shader = definition.shader or 'dissolve',
			shadow_height = definition.shadow_height,
			send = definition.send,
			no_tilt = definition.no_tilt,
			other_obj = definition.other_obj,
			ms = definition.ms,
			mr = definition.mr,
			mx = definition.mx,
			my = definition.my,
		}
	end
end

--- Runs one shader pass, then draws either this quad or a projection onto
--- `other_obj`. Shadow passes temporarily offset/shrink VT so the shadow
--- falls behind and below the object; the transform is restored afterwards.
---
--- Uniform contract with resources/shaders/*.fs (order matters for some
--- drivers' uniform initialization): mouse_screen_pos, screen_scale,
--- hovering, dissolve, time, texture_details, image_details, burn_colour_1/2,
--- shadow — then any caller-supplied uniforms via the bulk send.
function GfxSprite:apply_shader_effect(_shader, _shadow_height, _send, _no_tilt, other_obj, ms, mr, mx, my, custom_shader, tilt_shadow)
	if not self.states.visible then return end

	local draw_major = self.role.draw_major or self

	-- Shadow pre-transform: offset along parallax direction, shrink slightly.
	if _shadow_height then
		self.VT.y = self.VT.y - draw_major.shadow_parallax.y * _shadow_height
		self.VT.x = self.VT.x - draw_major.shadow_parallax.x * _shadow_height
		self.VT.scale = self.VT.scale * (1 - 0.2 * _shadow_height)
	end

	if custom_shader then
		-- Caller-driven mode: send exactly the uniforms the step listed.
		if _send and G.SHADERS and G.SHADERS[_shader] then
			for _, uniform in ipairs(_send) do
				pcall(function()
					G.SHADERS[_shader]:send(uniform.name,
						uniform.val or (uniform.func and uniform.func()) or uniform.ref_table[uniform.ref_value])
				end)
			end
		end
	else
		local sh = sprite_util.shader_for(_shader)
		if sh then
			self.ARGS.prep_shader = self.ARGS.prep_shader or {}
			self.ARGS.prep_shader.cursor_pos = self.ARGS.prep_shader.cursor_pos or {}
			self.ARGS.prep_shader.cursor_pos[1] =
				draw_major.tilt_var and draw_major.tilt_var.mx * G.CANVAS_SCALE
				or (G.INPUT and G.INPUT.cursor_position and G.INPUT.cursor_position.x * G.CANVAS_SCALE or 0)
			self.ARGS.prep_shader.cursor_pos[2] =
				draw_major.tilt_var and draw_major.tilt_var.my * G.CANVAS_SCALE
				or (G.INPUT and G.INPUT.cursor_position and G.INPUT.cursor_position.y * G.CANVAS_SCALE or 0)

			pcall(function()
				sh:send('mouse_screen_pos', self.ARGS.prep_shader.cursor_pos)
				sh:send('screen_scale', G.TILESCALE * G.TILESIZE * (draw_major.mouse_damping or 1) * G.CANVAS_SCALE)
				sh:send('hovering', ((_shadow_height and not tilt_shadow) or _no_tilt) and 0
					or (draw_major.hover_tilt or 0) * (tilt_shadow or 1))
				sh:send('dissolve', math.abs(draw_major.dissolve or 0))
				if _shader == 'dissolve' then
					sh:send('dissolve_wipe', draw_major.dissolve_wipe or 0)
				end
				-- Real time so foil/holo sweeps actually animate each frame.
				-- gold_seal uses REAL alone (sent after this pcall) so a failed
				-- earlier uniform cannot leave the shimmer clock stuck at 0.
				if _shader ~= 'gold_seal' then
					local id_phase = 123.33412 * ((tonumber(draw_major.ID) or 0) / 1.14212) % 3000
					sh:send('time', id_phase + (G.TIMERS and G.TIMERS.REAL or 0))
				end
				sh:send('texture_details', self:texture_descriptor())
				sh:send('image_details', self:image_dimensions())
				sh:send('burn_colour_1', draw_major.dissolve_colours and draw_major.dissolve_colours[1] or G.C.CLEAR)
				sh:send('burn_colour_2', draw_major.dissolve_colours and draw_major.dissolve_colours[2] or G.C.CLEAR)
				sh:send('shadow', (not not _shadow_height))
				if _shader ~= 'gold_seal' and _send then
					sh:send(_shader, _send)
				end
			end)
			-- Own pcall: still animates if texture_details / burn_colour send failed.
			if _shader == 'gold_seal' then
				pcall(function()
					local clock = (G.TIMERS and G.TIMERS.REAL) or 0
					sh:send('time', clock)
					sh:send('gold_seal', clock, clock, 0, 1)
				end)
			end
		end
	end

	local active_shader = sprite_util.shader_for(_shader)
	if active_shader then love.graphics.setShader(active_shader) end

	if other_obj then
		self:project_onto(other_obj, ms, mr, mx, my)
	else
		self:draw_self()
	end

	love.graphics.setShader()

	if _shadow_height then -- undo the shadow pre-transform exactly
		self.VT.y = self.VT.y + draw_major.shadow_parallax.y * _shadow_height
		self.VT.x = self.VT.x + draw_major.shadow_parallax.x * _shadow_height
		self.VT.scale = self.VT.scale / (1 - 0.2 * _shadow_height)
	end
end
end
