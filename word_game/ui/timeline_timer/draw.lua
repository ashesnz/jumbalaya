--[[ word_game/ui/timeline_timer/draw.lua - timeline HUD render pass ]]

local Layout = require("word_game.ui.layout")
local StageLabel = require("word_game.ui.stage_label")

local M = {}

function M.draw(timer, layout)
	if not love or not love.graphics or not love.graphics.polygon then return end
	if not G.GAME or not G.ROOM then return end
	if G.STATE ~= G.STATES.TABLE_BOARD then return end
	local vis = timer.intro_visible
	if vis == nil then vis = 1 end
	if vis <= 0.001 then return end

	local ts = (G.TILESCALE or 1) * (G.TILESIZE or 1)
	local rect = Layout.timeline_rect and Layout.timeline_rect() or Layout.portrait_rect()
	local w = rect.w * ts
	local h = rect.h * ts
	local slant = (rect.slant or (rect.h * 0.88)) * ts
	local x = rect.x * ts
	local y = rect.y * ts
	local r = math.max(4, h * 0.18)

	local prev_font = love.graphics.getFont and love.graphics.getFont()
	local cr, cg, cb, ca = 1, 1, 1, 1
	if love.graphics.getColor then
		cr, cg, cb, ca = love.graphics.getColor()
	end
	local prev_shader = love.graphics.getShader and love.graphics.getShader()

	love.graphics.push()
	love.graphics.setShader()
	layout.room_translate()

	local cx = x + w * 0.5
	local cy = y + h * 0.5
	if vis < 0.999 then
		love.graphics.translate(cx, cy)
		love.graphics.scale(0.72 + 0.28 * vis, vis)
		love.graphics.translate(-cx, -cy)
	end

	if love.graphics.setLineStyle then
		love.graphics.setLineStyle("smooth")
	end
	if love.graphics.setLineJoin then
		love.graphics.setLineJoin("bevel")
	end

	StageLabel.draw_above_timer(x, y, w, h)

	local shake = timer.display_shake_strength()
	if shake > 0 then
		love.graphics.push()
		local real_time = (G.TIMERS and G.TIMERS.REAL) or 0
		local ox = math.sin(real_time * 52) * shake
		local oy = math.cos(real_time * 47) * shake * 0.72
		love.graphics.translate(ox, oy)
	end

	local shape_verts = layout.build_shape_polygon(x, y, w, h, slant, r)

	for i = 4, 1, -1 do
		love.graphics.setColor(layout.SHADOW_COLOR[1], layout.SHADOW_COLOR[2], layout.SHADOW_COLOR[3], layout.SHADOW_COLOR[4] * (i / 4))
		local shadow_verts = layout.build_shape_polygon(x + i * 0.8, y + i * 1.8, w, h, slant, r)
		love.graphics.polygon("fill", unpack(shadow_verts))
	end

	local frac_remaining
	local frac_filled
	local top_split_x
	local bot_split_x
	if timer.is_progress_mode() then
		frac_filled = layout.clamp01(timer.display_frac or 0)
		frac_remaining = 1 - frac_filled
		top_split_x = x + (w - slant) * frac_filled
		bot_split_x = x + w * frac_filled
	else
		frac_remaining = layout.clamp01(timer.time_remaining / timer.TOTAL_DURATION)
		top_split_x = x + (w - slant) * frac_remaining
		bot_split_x = x + w * frac_remaining
	end

	love.graphics.setColor(layout.RED_MID)
	love.graphics.polygon("fill", unpack(shape_verts))

	if timer.is_progress_mode() then
		local green_verts = layout.build_green_polygon(x, y, w, h, slant, r, frac_filled)
		if green_verts then
			love.graphics.setColor(layout.GREEN_MID)
			love.graphics.polygon("fill", unpack(green_verts))
		end
	else
		local green_verts = layout.build_green_polygon(x, y, w, h, slant, r, frac_remaining)
		if green_verts then
			love.graphics.setColor(layout.GREEN_MID)
			love.graphics.polygon("fill", unpack(green_verts))
		end
	end

	local seam_active = timer.is_progress_mode()
		and timer.display_combo_level() > 0.04
		and frac_filled > 0.001 and frac_filled < 0.999
		or (not timer.is_progress_mode() and frac_remaining > 0.001 and frac_remaining < 0.999)
	if seam_active then
		local real_time = (G.TIMERS and G.TIMERS.REAL) or 0
		local flicker = math.sin(real_time * 24) * 0.15 + math.cos(real_time * 37) * 0.1
		local level = timer.is_progress_mode() and timer.display_combo_level() or 1
		local glow_scale = timer.is_progress_mode() and timer.display_smoke_glow_scale() or 1
		local glow_alpha = timer.is_progress_mode() and (0.75 + flicker + (level - 1) * 0.08) or (0.75 + flicker)

		love.graphics.setLineWidth(math.max(6, h * 0.18) * glow_scale)
		love.graphics.setColor(layout.SPARK_GLOW[1], layout.SPARK_GLOW[2], layout.SPARK_GLOW[3], math.min(1, glow_alpha))
		love.graphics.line(top_split_x, y - 2, bot_split_x, y + h + 2)

		love.graphics.setLineWidth(math.max(2.5, h * 0.08) * (0.85 + glow_scale * 0.15))
		love.graphics.setColor(layout.SPARK_CORE[1], layout.SPARK_CORE[2], layout.SPARK_CORE[3], 0.95)
		love.graphics.line(top_split_x, y, bot_split_x, y + h)

		local mid_fuse_x = (top_split_x + bot_split_x) * 0.5
		local mid_fuse_y = y + h * 0.5
		local core_r = math.max(3, h * 0.14) * glow_scale
		local halo_r = math.max(6, h * 0.28) * glow_scale
		love.graphics.setColor(layout.SPARK_CORE[1], layout.SPARK_CORE[2], layout.SPARK_CORE[3], math.min(1, 0.85 + flicker))
		love.graphics.circle("fill", mid_fuse_x, mid_fuse_y, core_r)
		love.graphics.setColor(layout.SPARK_GLOW[1], layout.SPARK_GLOW[2], layout.SPARK_GLOW[3], math.min(1, 0.45 + (glow_scale - 1) * 0.22))
		love.graphics.circle("fill", mid_fuse_x, mid_fuse_y, halo_r)
		if glow_scale > 1.2 then
			love.graphics.setColor(layout.SPARK_GLOW[1], layout.SPARK_GLOW[2], layout.SPARK_GLOW[3], math.min(0.55, 0.18 + (glow_scale - 1) * 0.12))
			love.graphics.circle("fill", mid_fuse_x, mid_fuse_y, halo_r * 1.45)
		end
	end

	if timer.is_progress_mode() and timer.goal_reached then
		local goal_frac = timer.display_goal_marker_fraction()
		if goal_frac < 0.995 then
			local goal_top = x + (w - slant) * goal_frac
			local goal_bot = x + w * goal_frac
			love.graphics.setLineWidth(math.max(5, h * 0.12))
			love.graphics.setColor(1, 0.92, 0.45, 0.5)
			love.graphics.line(goal_top, y - 1, goal_bot, y + h + 1)
			love.graphics.setLineWidth(math.max(2.5, h * 0.055))
			love.graphics.setColor(1, 1, 1, 0.95)
			love.graphics.line(goal_top, y, goal_bot, y + h)
		end
	end

	love.graphics.setLineWidth(math.max(2.5, h * 0.065))
	love.graphics.setColor(layout.BORDER_COLOR[1], layout.BORDER_COLOR[2], layout.BORDER_COLOR[3], layout.BORDER_COLOR[4])
	love.graphics.polygon("line", unpack(shape_verts))

	local mid_fuse_x = (top_split_x + bot_split_x) * 0.5
	local mid_fuse_y = y + h * 0.5
	for _, s in ipairs(timer.sparks) do
		local sx = mid_fuse_x + s.x
		local sy = mid_fuse_y + s.y
		love.graphics.setColor(s.color[1], s.color[2], s.color[3], s.alpha)
		love.graphics.circle("fill", sx, sy, s.size)
	end

	local count_str = timer.is_progress_mode()
		and layout.format_progress_label(timer)
		or layout.format_time(timer, timer.time_remaining)
	local font_px = math.max(16, h * 0.62)
	local font = layout.timer_font(font_px)

	if font then
		love.graphics.setFont(font)
		local tw = font:getWidth(count_str)
		local th = font:getHeight()
		local text_cx = x + (w - slant * 0.5) * 0.5
		local text_cy = y + h * 0.5

		love.graphics.setColor(0.04, 0.06, 0.12, 0.90)
		for ox = -1.5, 1.5, 1.5 do
			for oy = -1.5, 1.5, 1.5 do
				if ox ~= 0 or oy ~= 0 then
					love.graphics.print(count_str, text_cx - tw * 0.5 + ox, text_cy - th * 0.5 + oy + 0.5)
				end
			end
		end

		love.graphics.setColor(0.02, 0.03, 0.06, 0.85)
		love.graphics.print(count_str, text_cx - tw * 0.5 + 1.5, text_cy - th * 0.5 + 2.0)

		if timer.is_progress_mode() and (timer.goal_reached or timer.frozen_for_reward) then
			local pulse = math.abs(math.sin(((G.TIMERS and G.TIMERS.REAL) or 0) * 6))
			love.graphics.setColor(1.0, 0.95 - pulse * 0.2, 0.55 - pulse * 0.15, 1)
		elseif not timer.is_progress_mode() and timer.time_remaining <= 10 and timer.time_remaining > 0 then
			local pulse_red = math.abs(math.sin(((G.TIMERS and G.TIMERS.REAL) or 0) * 8))
			love.graphics.setColor(1.0, 0.85 - pulse_red * 0.35, 0.85 - pulse_red * 0.35, 1)
		else
			love.graphics.setColor(1.0, 1.0, 1.0, 1.0)
		end
		love.graphics.print(count_str, text_cx - tw * 0.5, text_cy - th * 0.5)
	end

	if shake > 0 then
		love.graphics.pop()
	end

	love.graphics.pop()
	if prev_font and love.graphics.setFont then
		love.graphics.setFont(prev_font)
	end
	if love.graphics.setColor then
		love.graphics.setColor(cr, cg, cb, ca)
	end
	if prev_shader and love.graphics.setShader then
		love.graphics.setShader(prev_shader)
	end
end

return M
