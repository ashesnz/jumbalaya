--[[ app/loop/postfx.lua - CRT shader post-processing after canvas draw ]]

local M = {}

function M.apply(game)
	if G.recording_mode and not G.video_control then
		return
	end

	G.ARGS.eased_cursor_pos = G.ARGS.eased_cursor_pos or {
		x = G.POINTER.T.x,
		y = G.POINTER.T.y,
		sx = (G.INPUT and G.INPUT.cursor_position and G.INPUT.cursor_position.x) or 0,
		sy = (G.INPUT and G.INPUT.cursor_position and G.INPUT.cursor_position.y) or 0,
	}
	G.screenwipe_amt = G.screenwipe_amt and (0.95 * G.screenwipe_amt + 0.05 * ((game.screenwipe and 0.4 or game.screenglitch and 0.4) or 0)) or 1
	G.SETTINGS.GRAPHICS.crt = (G.SETTINGS.GRAPHICS.crt or 0) * 0.3
	local os_name = love.system and love.system.getOS and love.system.getOS() or ""
	local use_crt = os_name ~= 'iOS' and os_name ~= 'Android'
	if use_crt and G.SHADERS and G.SHADERS['CRT'] then
		pcall(function()
			G.SHADERS['CRT']:send('distortion_fac', {1.0 + 0.07 * G.SETTINGS.GRAPHICS.crt / 100, 1.0 + 0.1 * G.SETTINGS.GRAPHICS.crt / 100})
			G.SHADERS['CRT']:send('scale_fac', {1.0 - 0.008 * G.SETTINGS.GRAPHICS.crt / 100, 1.0 - 0.008 * G.SETTINGS.GRAPHICS.crt / 100})
			G.SHADERS['CRT']:send('feather_fac', 0.01)
			G.SHADERS['CRT']:send('bloom_fac', (G.SETTINGS.GRAPHICS.bloom or 1) - 1)
			G.SHADERS['CRT']:send('time', 400 + (G.TIMERS.REAL or 0))
			G.SHADERS['CRT']:send('noise_fac', 0.001 * G.SETTINGS.GRAPHICS.crt / 100)
			G.SHADERS['CRT']:send('crt_intensity', 0.16 * G.SETTINGS.GRAPHICS.crt / 100)
			G.SHADERS['CRT']:send('glitch_intensity', 0.1 * G.SETTINGS.GRAPHICS.crt / 100 + (G.screenwipe_amt or 0))
			local scan_h = (game.CANVAS and game.CANVAS.getPixelHeight and game.CANVAS:getPixelHeight()) or (love.graphics.getHeight and love.graphics.getHeight()) or 720
			G.SHADERS['CRT']:send('scanlines', scan_h * 0.75 / G.CANVAS_SCALE)
			G.SHADERS['CRT']:send('mouse_screen_pos', G.video_control and {love.graphics.getWidth() / 2, love.graphics.getHeight() / 2} or {G.ARGS.eased_cursor_pos.sx, G.ARGS.eased_cursor_pos.sy})
			G.SHADERS['CRT']:send('screen_scale', G.TILESCALE * G.TILESIZE)
			G.SHADERS['CRT']:send('hovering', 1)
			love.graphics.setShader(G.SHADERS['CRT'])
		end)
	end
	G.SETTINGS.GRAPHICS.crt = (G.SETTINGS.GRAPHICS.crt or 0) / 0.3
end

return M
