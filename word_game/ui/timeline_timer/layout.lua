--[[ word_game/ui/timeline_timer/layout.lua - geometry, fonts, and label formatting ]]

local FONT_FILE = "resources/fonts/Outfit-Bold.ttf"
local font_cache = {}

local M = {}

M.GREEN_TOP = { 0.38, 0.88, 0.48, 1 }
M.GREEN_MID = { 0.22, 0.78, 0.35, 1 }
M.GREEN_BOT = { 0.14, 0.60, 0.24, 1 }

M.RED_TOP = { 0.95, 0.28, 0.32, 1 }
M.RED_MID = { 0.82, 0.16, 0.22, 1 }
M.RED_BOT = { 0.58, 0.08, 0.14, 1 }

M.SPARK_CORE = { 1.00, 0.98, 0.85, 1 }
M.SPARK_GLOW = { 1.00, 0.65, 0.12, 0.85 }
M.BORDER_COLOR = { 0.10, 0.15, 0.26, 1 }
M.SHADOW_COLOR = { 0.03, 0.05, 0.10, 0.35 }

function M.clamp01(t)
	if t < 0 then return 0 end
	if t > 1 then return 1 end
	return t
end

function M.timer_font(px)
	px = math.max(12, math.floor(px + 0.5))
	local cached = font_cache[px]
	if cached then return cached end
	local font = nil
	if love and love.graphics and love.graphics.newFont then
		local ok, f = pcall(love.graphics.newFont, FONT_FILE, px)
		if ok and f then
			font = f
		else
			font = love.graphics.newFont(px)
		end
		font:setFilter("linear", "linear")
	end
	font_cache[px] = font
	return font
end

function M.room_translate()
	local room = G and G.ROOM
	if not room or not love or not love.graphics then return end
	local ts = (G.TILESCALE or 1) * (G.TILESIZE or 1)
	love.graphics.translate(room.T.w * ts * 0.5, room.T.h * ts * 0.5)
	love.graphics.rotate(room.T.r or 0)
	love.graphics.translate(
		-room.T.w * ts * 0.5 + (room.T.x or 0) * ts,
		-room.T.h * ts * 0.5 + (room.T.y or 0) * ts
	)
end

function M.format_time(timer, time_val)
	local t = math.max(0, time_val or 0)
	if timer.frozen_for_reward then
		return string.format("%d", math.floor(t + 1e-9))
	end
	if t >= 10 then
		return string.format("%d", math.floor(t + 1e-9))
	elseif t >= 5 then
		return string.format("%.1f", t)
	else
		return string.format("%.2f", t)
	end
end

function M.format_progress_label(timer)
	local banked = timer.progress_score or 0
	local target = math.max(1, timer.progress_target or 1)
	local pending = timer.progress_pending or 0
	local projected = banked + pending
	if timer.score_roll then
		local shown = math.floor(banked + 0.5)
		return string.format("%d / %d", shown, target)
	end
	if timer.frozen_for_reward then
		return string.format("%d", math.floor(banked + 0.5))
	end
	if projected >= target then
		return string.format("%d / %d", math.floor(projected + 0.5), target)
	end
	local animated = math.floor(M.clamp01(timer.display_frac or 0) * target + 0.5)
	local shown = math.min(target, math.max(animated, projected))
	return string.format("%d / %d", shown, target)
end

function M.build_shape_polygon(x, y, w, h, slant, r, n_arc)
	n_arc = n_arc or 6
	local verts = {}

	for i = 0, n_arc do
		local ang = math.pi + (math.pi * 0.5) * (i / n_arc)
		table.insert(verts, x + r + r * math.cos(ang))
		table.insert(verts, y + r + r * math.sin(ang))
	end

	local tr_x = x + w - slant
	local tr_y = y
	local slant_ang = math.atan2(h, slant)
	table.insert(verts, tr_x - r * 0.5)
	table.insert(verts, tr_y)
	table.insert(verts, tr_x + r * 0.3 * math.cos(slant_ang))
	table.insert(verts, tr_y + r * 0.3 * math.sin(slant_ang))

	local br_x = x + w
	local br_y = y + h
	table.insert(verts, br_x - r * 0.3 * math.cos(slant_ang))
	table.insert(verts, br_y - r * 0.3 * math.sin(slant_ang))
	table.insert(verts, br_x - r * 0.5)
	table.insert(verts, br_y)

	for i = 0, n_arc do
		local ang = (math.pi * 0.5) + (math.pi * 0.5) * (i / n_arc)
		table.insert(verts, x + r + r * math.cos(ang))
		table.insert(verts, y + h - r + r * math.sin(ang))
	end

	return verts
end

function M.build_green_polygon(x, y, w, h, slant, r, frac, n_arc)
	if frac <= 0.001 then return nil end
	if frac >= 0.999 then
		return M.build_shape_polygon(x, y, w, h, slant, r, n_arc)
	end

	n_arc = n_arc or 6
	local verts = {}

	for i = 0, n_arc do
		local ang = math.pi + (math.pi * 0.5) * (i / n_arc)
		table.insert(verts, x + r + r * math.cos(ang))
		table.insert(verts, y + r + r * math.sin(ang))
	end

	local top_split_x = x + (w - slant) * frac
	local bot_split_x = x + w * frac
	table.insert(verts, top_split_x)
	table.insert(verts, y)
	table.insert(verts, bot_split_x)
	table.insert(verts, y + h)

	for i = 0, n_arc do
		local ang = (math.pi * 0.5) + (math.pi * 0.5) * (i / n_arc)
		table.insert(verts, x + r + r * math.cos(ang))
		table.insert(verts, y + h - r + r * math.sin(ang))
	end

	return verts
end

return M
