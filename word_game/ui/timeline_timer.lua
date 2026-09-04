--[[
	word_game/ui/timeline_timer.lua - Timeline HUD (timer fuse or classic score slider).

	Time Run: burning fuse countdown (60s → 0).
	Classic: score progress bar toward the stage target (dice-have-no-eyes style).
]]

local Layout = require("word_game.ui.layout")
local StageLabel = require("word_game.ui.stage_label")
local RunMode = require("word_game.model.run_mode")

local M = {}

M.TOTAL_DURATION = 60.0
M.time_remaining = 60.0
M.is_active = true
M.frozen_for_reward = false
M.sparks = {}

M.progress_target = 1
M.progress_score = 0
M.progress_pending = 0
M.display_frac = 0
M.display_goal_frac = 1
M.goal_reached = false
M.post_target_scoring = false
M.post_target_pulse = 0
M.puzzle_word_count = 0
M.smoke_active = false
M.slide_boost_t = 0
M.display_combo = 0
M.score_roll = nil

local SMOKE_WORD_THRESHOLD = 3
local SHAKE_WORD_THRESHOLD = 5
local COMBO_RISE_SPEED = 14
local COMBO_FALL_SPEED = 2.6
local SHAKE_COMBO_OFFSET = SHAKE_WORD_THRESHOLD - SMOKE_WORD_THRESHOLD

local function combo_level(word_count)
	word_count = word_count or 0
	if word_count < SMOKE_WORD_THRESHOLD then return 0 end
	return word_count - SMOKE_WORD_THRESHOLD + 1
end

local function glow_scale_for(level)
	if level <= 0 then return 1 end
	return 1 + (level - 1) * 0.38
end

local function spawn_chance_for(level)
	if level <= 0 then return 0 end
	return math.min(0.98, 0.62 + (level - 1) * 0.14)
end

local function particle_cap_for(level)
	if level <= 0 then return 0 end
	return math.min(72, 22 + level * 10)
end

local function shake_for_combo(level)
	if level <= SHAKE_COMBO_OFFSET then return 0 end
	return (level - SHAKE_COMBO_OFFSET) * 1.6
end

local function target_combo_level()
	return combo_level(M.puzzle_word_count)
end

local function display_combo_level()
	return M.display_combo or 0
end

function M.combo_level()
	return target_combo_level()
end

function M.display_combo_level()
	return display_combo_level()
end

function M.smoke_glow_scale()
	return glow_scale_for(target_combo_level())
end

function M.display_smoke_glow_scale()
	return glow_scale_for(display_combo_level())
end

function M.smoke_spawn_chance()
	return spawn_chance_for(target_combo_level())
end

function M.display_smoke_spawn_chance()
	return spawn_chance_for(display_combo_level())
end

function M.smoke_particle_cap()
	return particle_cap_for(target_combo_level())
end

function M.display_smoke_particle_cap()
	return particle_cap_for(display_combo_level())
end

function M.shake_strength()
	if not M.is_progress_mode() or M.frozen_for_reward then return 0 end
	return shake_for_combo(target_combo_level())
end

function M.display_shake_strength()
	if not M.is_progress_mode() or M.frozen_for_reward then return 0 end
	return shake_for_combo(display_combo_level())
end

function M.update_display_intensity(dt)
	if not M.is_progress_mode() then
		M.display_combo = 0
		return
	end
	local target = target_combo_level()
	if target > M.display_combo then
		M.display_combo = M.display_combo + (target - M.display_combo) * math.min(1, dt * COMBO_RISE_SPEED)
	elseif target < M.display_combo then
		M.display_combo = M.display_combo + (target - M.display_combo) * math.min(1, dt * COMBO_FALL_SPEED)
	end
	if target == 0 and M.display_combo < 0.02 then
		M.display_combo = 0
	end
end

local FONT_FILE = "resources/fonts/Outfit-Bold.ttf"
local font_cache = {}

local GREEN_TOP = { 0.38, 0.88, 0.48, 1 }
local GREEN_MID = { 0.22, 0.78, 0.35, 1 }
local GREEN_BOT = { 0.14, 0.60, 0.24, 1 }

local RED_TOP = { 0.95, 0.28, 0.32, 1 }
local RED_MID = { 0.82, 0.16, 0.22, 1 }
local RED_BOT = { 0.58, 0.08, 0.14, 1 }

local SPARK_CORE = { 1.00, 0.98, 0.85, 1 }
local SPARK_GLOW = { 1.00, 0.65, 0.12, 0.85 }
local BORDER_COLOR = { 0.10, 0.15, 0.26, 1 }
local SHADOW_COLOR = { 0.03, 0.05, 0.10, 0.35 }

local function clamp01(t)
	if t < 0 then return 0 end
	if t > 1 then return 1 end
	return t
end

local function timer_font(px)
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

local function room_translate()
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

-- Formats the countdown timer text:
-- Whole number (>= 10s), 1 decimal point (< 10s and >= 5s), 2 decimal points (< 5s).
function M.is_progress_mode()
	return RunMode.is_classic()
end

function M.sync_progress()
	if not M.is_progress_mode() then return end
	if M.frozen_for_reward or M.score_roll then return end
	local wr = G.GAME and G.GAME.word_round
	local j = wr and wr.jumble
	local target = math.max(1, (wr and wr.target) or M.progress_target or 1)
	local banked = (j and j.total_score) or 0
	local pending = 0
	if j and (j.puzzle_points or 0) > 0 then
		pending = math.floor((j.puzzle_points or 0) * (j.puzzle_multi or 1))
	end
	M.progress_target = target
	M.progress_score = banked
	M.progress_pending = pending
	M.puzzle_word_count = #(j and j.puzzle_words or {})
	M.smoke_active = M.puzzle_word_count >= SMOKE_WORD_THRESHOLD
	M.goal_reached = (banked + pending) >= target
	M.post_target_scoring = M.goal_reached
end

function M.pulse_post_target()
	M.post_target_pulse = 1
end

function M.progress_score_total()
	return (M.progress_score or 0) + (M.progress_pending or 0)
end

function M.progress_total_fraction()
	local target = math.max(1, M.progress_target or 1)
	local score = M.progress_score_total()
	if score >= target then
		return 1
	end
	return clamp01(score / target)
end

--- Vertical goal seam when classic target is met; moves left as score exceeds target.
function M.progress_goal_marker_fraction()
	if not M.goal_reached then return nil end
	local target = math.max(1, M.progress_target or 1)
	local score = math.max(target, M.progress_score_total())
	return clamp01(target / score)
end

function M.display_goal_marker_fraction()
	return M.display_goal_frac or 1
end

function M.on_word_played(_old_total, _new_total)
	if not M.is_progress_mode() or M.frozen_for_reward then return end
	M.sync_progress()
	local target = target_combo_level()
	if target > M.display_combo then
		M.display_combo = target
	end
	M.slide_boost_t = 0.4
end

function M.reset_puzzle_smoke()
	M.slide_boost_t = 0
end

function M.format_progress_label()
	local banked = M.progress_score or 0
	local target = math.max(1, M.progress_target or 1)
	local pending = M.progress_pending or 0
	local projected = banked + pending
	if M.score_roll then
		local shown = math.floor(banked + 0.5)
		return string.format("%d / %d", shown, target)
	end
	if M.frozen_for_reward then
		return string.format("%d", math.floor(banked + 0.5))
	end
	if projected >= target then
		return string.format("%d / %d", math.floor(projected + 0.5), target)
	end
	local animated = math.floor(clamp01(M.display_frac or 0) * target + 0.5)
	local shown = math.min(target, math.max(animated, projected))
	return string.format("%d / %d", shown, target)
end

function M.progress_fill_fraction()
	local target = math.max(1, M.progress_target or 1)
	local score = M.progress_score or 0
	return clamp01(score / target)
end

function M.progress_pending_fraction()
	local target = math.max(1, M.progress_target or 1)
	local score = M.progress_score or 0
	local pending = M.progress_pending or 0
	if pending <= 0 then return 0, M.progress_fill_fraction() end
	local from_frac = clamp01(score / target)
	local to_frac = clamp01((score + pending) / target)
	return from_frac, to_frac
end

function M.format_time(time_val)
	local t = math.max(0, time_val or 0)
	if M.frozen_for_reward then
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

-- Builds polygon vertices for the timeline shape: rounded left edge, straight top/bottom, slanted right edge.
function M.build_shape_polygon(x, y, w, h, slant, r, n_arc)
	n_arc = n_arc or 6
	local verts = {}

	-- 1. Top-left rounded arc (180 to 270 deg)
	for i = 0, n_arc do
		local ang = math.pi + (math.pi * 0.5) * (i / n_arc)
		table.insert(verts, x + r + r * math.cos(ang))
		table.insert(verts, y + r + r * math.sin(ang))
	end

	-- 2. Top-right slanted corner
	local tr_x = x + w - slant
	local tr_y = y
	local slant_ang = math.atan2(h, slant)
	table.insert(verts, tr_x - r * 0.5)
	table.insert(verts, tr_y)
	table.insert(verts, tr_x + r * 0.3 * math.cos(slant_ang))
	table.insert(verts, tr_y + r * 0.3 * math.sin(slant_ang))

	-- 3. Bottom-right slanted corner
	local br_x = x + w
	local br_y = y + h
	table.insert(verts, br_x - r * 0.3 * math.cos(slant_ang))
	table.insert(verts, br_y - r * 0.3 * math.sin(slant_ang))
	table.insert(verts, br_x - r * 0.5)
	table.insert(verts, br_y)

	-- 4. Bottom-left rounded arc (90 to 180 deg)
	for i = 0, n_arc do
		local ang = (math.pi * 0.5) + (math.pi * 0.5) * (i / n_arc)
		table.insert(verts, x + r + r * math.cos(ang))
		table.insert(verts, y + h - r + r * math.sin(ang))
	end

	return verts
end

-- Builds polygon vertices for the remaining green portion
function M.build_green_polygon(x, y, w, h, slant, r, frac, n_arc)
	if frac <= 0.001 then return nil end
	if frac >= 0.999 then
		return M.build_shape_polygon(x, y, w, h, slant, r, n_arc)
	end

	n_arc = n_arc or 6
	local verts = {}

	-- 1. Top-left rounded arc (180 to 270 deg)
	for i = 0, n_arc do
		local ang = math.pi + (math.pi * 0.5) * (i / n_arc)
		table.insert(verts, x + r + r * math.cos(ang))
		table.insert(verts, y + r + r * math.sin(ang))
	end

	-- 2. Slanted right edge at the current fuse split
	local top_split_x = x + (w - slant) * frac
	local bot_split_x = x + w * frac
	table.insert(verts, top_split_x)
	table.insert(verts, y)
	table.insert(verts, bot_split_x)
	table.insert(verts, y + h)

	-- 3. Bottom-left rounded arc (90 to 180 deg)
	for i = 0, n_arc do
		local ang = (math.pi * 0.5) + (math.pi * 0.5) * (i / n_arc)
		table.insert(verts, x + r + r * math.cos(ang))
		table.insert(verts, y + h - r + r * math.sin(ang))
	end

	return verts
end

function M.reset(duration)
	M.TOTAL_DURATION = duration or 60.0
	M.time_remaining = M.TOTAL_DURATION
	M.is_active = not M.is_progress_mode()
	M.frozen_for_reward = false
	M.sparks = {}
	M.progress_score = 0
	M.progress_pending = 0
	M.display_frac = 0
	M.display_goal_frac = 1
	M.goal_reached = false
	M.post_target_scoring = false
	M.post_target_pulse = 0
	M.puzzle_word_count = 0
	M.smoke_active = false
	M.slide_boost_t = 0
	M.display_combo = 0
	M.score_roll = nil
	local wr = G.GAME and G.GAME.word_round
	M.progress_target = math.max(1, (wr and wr.target) or 1)
	M.sync_progress()
	StageLabel.sync()
	if WORD_GAME and WORD_GAME.VaultStageButton and WORD_GAME.VaultStageButton.reset then
		WORD_GAME.VaultStageButton.reset()
	end
end

function M.reset_progress(target)
	M.is_active = false
	M.frozen_for_reward = false
	M.score_roll = nil
	M.sparks = {}
	M.progress_target = math.max(1, target or 1)
	M.progress_score = 0
	M.progress_pending = 0
	M.display_frac = 0
	M.display_goal_frac = 1
	M.goal_reached = false
	M.post_target_scoring = false
	M.post_target_pulse = 0
	M.puzzle_word_count = 0
	M.smoke_active = false
	M.slide_boost_t = 0
	M.display_combo = 0
	M.sync_progress()
	StageLabel.sync()
	if WORD_GAME and WORD_GAME.VaultStageButton and WORD_GAME.VaultStageButton.reset then
		WORD_GAME.VaultStageButton.reset()
	end
end

function M.start_score_roll(from, to, duration)
	from = math.max(0, math.floor(from or 0))
	to = math.max(0, math.floor(to or 0))
	duration = duration or 0.75
	M.progress_score = from
	M.progress_pending = 0
	M.display_frac = clamp01(from / math.max(1, M.progress_target or 1))
	M.display_goal_frac = M.progress_goal_marker_fraction() or 1
	M.goal_reached = from >= (M.progress_target or 1)
	M.is_active = false
	M.frozen_for_reward = true
	M.score_roll = { from = from, to = to, t = 0, dur = duration }
end

function M.pause()
	M.is_active = false
	M.frozen_for_reward = false
end

function M.resume()
	M.is_active = true
	M.frozen_for_reward = false
end

function M.freeze_reward_display(token_amount)
	token_amount = math.max(0, math.floor(token_amount or 0))
	if M.is_progress_mode() then
		M.progress_score = token_amount
		M.progress_pending = 0
		M.display_frac = clamp01(token_amount / math.max(1, M.progress_target or 1))
		M.display_goal_frac = M.progress_goal_marker_fraction() or 1
		M.goal_reached = token_amount >= (M.progress_target or 1)
	else
		M.time_remaining = token_amount
	end
	M.is_active = false
	M.frozen_for_reward = true
end

function M.set_time(time_seconds)
	M.time_remaining = math.max(0, math.min(M.TOTAL_DURATION, time_seconds or M.TOTAL_DURATION))
end

function M.add_time(seconds)
	seconds = seconds or 0
	if seconds <= 0 then return end
	M.time_remaining = math.min(M.TOTAL_DURATION, M.time_remaining + seconds)
end

local function ease_out_cubic(t)
	t = clamp01(t)
	local inv = 1 - t
	return 1 - inv * inv * inv
end

function M.update(dt)
	dt = dt or 0
	if M.is_progress_mode() then
		if M.score_roll then
			local roll = M.score_roll
			roll.t = roll.t + dt
			local u = ease_out_cubic(roll.t / roll.dur)
			local val = roll.from + (roll.to - roll.from) * u
			M.progress_score = val
			M.progress_pending = 0
			local target = math.max(1, M.progress_target or 1)
			M.display_frac = clamp01(val / target)
			if M.goal_reached then
				M.display_goal_frac = clamp01(target / math.max(target, val))
			end
			if roll.t >= roll.dur then
				M.progress_score = roll.to
				M.score_roll = nil
			end
		elseif not M.frozen_for_reward then
			M.sync_progress()
		end
		local target_frac = M.progress_total_fraction()
		local goal_frac = M.progress_goal_marker_fraction() or 1
		local boost = (M.slide_boost_t or 0) > 0 and 10 or 0
		if M.slide_boost_t and M.slide_boost_t > 0 then
			M.slide_boost_t = math.max(0, M.slide_boost_t - dt)
		end
		if M.post_target_pulse and M.post_target_pulse > 0 then
			M.post_target_pulse = math.max(0, M.post_target_pulse - dt * 2.4)
		end
		local lerp_speed = (M.frozen_for_reward and 12 or 8) + boost
		M.display_frac = M.display_frac + (target_frac - M.display_frac) * math.min(1, dt * lerp_speed)
		M.display_goal_frac = M.display_goal_frac + (goal_frac - M.display_goal_frac) * math.min(1, dt * lerp_speed)
		M.update_display_intensity(dt)
	else
		if M.is_active and M.time_remaining > 0 then
			M.time_remaining = math.max(0, M.time_remaining - dt)
		end
	end

	-- Update spark particles
	for i = #M.sparks, 1, -1 do
		local s = M.sparks[i]
		s.age = s.age + dt
		s.x = s.x + s.vx * dt
		s.y = s.y + s.vy * dt
		s.alpha = math.max(0, 1 - s.age / s.life)
		if s.age >= s.life then
			table.remove(M.sparks, i)
		end
	end

	StageLabel.update(dt)

	-- Spawn ember sparks at the animated slider edge (classic: eased combo intensity).
	local spark_active = false
	if M.is_progress_mode() then
		spark_active = M.display_combo_level() > 0.04
			and M.display_frac > 0.001
			and M.display_frac < 0.999
	else
		spark_active = M.time_remaining > 0 and M.time_remaining < M.TOTAL_DURATION
	end
	if spark_active then
		local level = M.is_progress_mode() and M.display_combo_level() or 1
		local cap = M.is_progress_mode() and M.display_smoke_particle_cap() or 25
		local chance = M.is_progress_mode() and M.display_smoke_spawn_chance() or 0.65
		if #M.sparks < cap and math.random() < chance then
			local size_boost = M.is_progress_mode() and (level * 0.55) or 0
			local speed_boost = M.is_progress_mode() and (level * 8) or 0
			table.insert(M.sparks, {
				x = (math.random() - 0.5) * (10 + level * 4),
				y = (math.random() - 0.5) * (6 + level * 2),
				vx = (math.random() - 0.5) * (35 + speed_boost),
				vy = -math.random(20 + level * 6, 65 + level * 12),
				size = math.random(2, 5) + size_boost,
				age = 0,
				life = 0.25 + math.random() * (0.35 + level * 0.08),
				alpha = 1,
				color = math.random() < 0.5 and SPARK_CORE or SPARK_GLOW,
			})
		end
	end
end

function M.draw()
	if not love or not love.graphics or not love.graphics.polygon then return end
	if not G.GAME or not G.ROOM then return end
	if G.STATE ~= G.STATES.TABLE_BOARD then return end

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
	room_translate()

	if love.graphics.setLineStyle then
		love.graphics.setLineStyle("smooth")
	end
	if love.graphics.setLineJoin then
		love.graphics.setLineJoin("bevel")
	end

	StageLabel.draw_above_timer(x, y, w, h)

	local shake = M.display_shake_strength()
	if shake > 0 then
		love.graphics.push()
		local real_time = (G.TIMERS and G.TIMERS.REAL) or 0
		local ox = math.sin(real_time * 52) * shake
		local oy = math.cos(real_time * 47) * shake * 0.72
		love.graphics.translate(ox, oy)
	end

	local shape_verts = M.build_shape_polygon(x, y, w, h, slant, r)

	-- 1. Outer drop shadow
	for i = 4, 1, -1 do
		love.graphics.setColor(SHADOW_COLOR[1], SHADOW_COLOR[2], SHADOW_COLOR[3], SHADOW_COLOR[4] * (i / 4))
		local shadow_verts = M.build_shape_polygon(x + i * 0.8, y + i * 1.8, w, h, slant, r)
		love.graphics.polygon("fill", unpack(shadow_verts))
	end

	local frac_remaining
	local frac_filled
	local top_split_x
	local bot_split_x
	if M.is_progress_mode() then
		frac_filled = clamp01(M.display_frac or 0)
		frac_remaining = 1 - frac_filled
		top_split_x = x + (w - slant) * frac_filled
		bot_split_x = x + w * frac_filled
	else
		frac_remaining = clamp01(M.time_remaining / M.TOTAL_DURATION)
		top_split_x = x + (w - slant) * frac_remaining
		bot_split_x = x + w * frac_remaining
	end

	-- 2. Draw timeline base (Red / unfilled track)
	love.graphics.setColor(RED_MID)
	love.graphics.polygon("fill", unpack(shape_verts))

	if M.is_progress_mode() then
		local green_verts = M.build_green_polygon(x, y, w, h, slant, r, frac_filled)
		if green_verts then
			love.graphics.setColor(GREEN_MID)
			love.graphics.polygon("fill", unpack(green_verts))
		end
	else
		local green_verts = M.build_green_polygon(x, y, w, h, slant, r, frac_remaining)
		if green_verts then
			love.graphics.setColor(GREEN_MID)
			love.graphics.polygon("fill", unpack(green_verts))
		end
	end

	-- Draw Glowing Fuse Burning Seam
	local seam_active = M.is_progress_mode()
		and M.display_combo_level() > 0.04
		and frac_filled > 0.001 and frac_filled < 0.999
		or (not M.is_progress_mode() and frac_remaining > 0.001 and frac_remaining < 0.999)
	if seam_active then
		local real_time = (G.TIMERS and G.TIMERS.REAL) or 0
		local flicker = math.sin(real_time * 24) * 0.15 + math.cos(real_time * 37) * 0.1
		local level = M.is_progress_mode() and M.display_combo_level() or 1
		local glow_scale = M.is_progress_mode() and M.display_smoke_glow_scale() or 1
		local glow_alpha = M.is_progress_mode() and (0.75 + flicker + (level - 1) * 0.08) or (0.75 + flicker)

		-- Outer glow along the seam
		love.graphics.setLineWidth(math.max(6, h * 0.18) * glow_scale)
		love.graphics.setColor(SPARK_GLOW[1], SPARK_GLOW[2], SPARK_GLOW[3], math.min(1, glow_alpha))
		love.graphics.line(top_split_x, y - 2, bot_split_x, y + h + 2)

		-- Core hot spark line
		love.graphics.setLineWidth(math.max(2.5, h * 0.08) * (0.85 + glow_scale * 0.15))
		love.graphics.setColor(SPARK_CORE[1], SPARK_CORE[2], SPARK_CORE[3], 0.95)
		love.graphics.line(top_split_x, y, bot_split_x, y + h)

		-- Glowing ember at the animated slider edge
		local mid_fuse_x = (top_split_x + bot_split_x) * 0.5
		local mid_fuse_y = y + h * 0.5
		local core_r = math.max(3, h * 0.14) * glow_scale
		local halo_r = math.max(6, h * 0.28) * glow_scale
		love.graphics.setColor(SPARK_CORE[1], SPARK_CORE[2], SPARK_CORE[3], math.min(1, 0.85 + flicker))
		love.graphics.circle("fill", mid_fuse_x, mid_fuse_y, core_r)
		love.graphics.setColor(SPARK_GLOW[1], SPARK_GLOW[2], SPARK_GLOW[3], math.min(1, 0.45 + (glow_scale - 1) * 0.22))
		love.graphics.circle("fill", mid_fuse_x, mid_fuse_y, halo_r)
		if glow_scale > 1.2 then
			love.graphics.setColor(SPARK_GLOW[1], SPARK_GLOW[2], SPARK_GLOW[3], math.min(0.55, 0.18 + (glow_scale - 1) * 0.12))
			love.graphics.circle("fill", mid_fuse_x, mid_fuse_y, halo_r * 1.45)
		end
	end

	if M.is_progress_mode() and M.goal_reached then
		local goal_frac = M.display_goal_marker_fraction()
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

	-- 3. Outer border outline
	love.graphics.setLineWidth(math.max(2.5, h * 0.065))
	love.graphics.setColor(BORDER_COLOR[1], BORDER_COLOR[2], BORDER_COLOR[3], BORDER_COLOR[4])
	love.graphics.polygon("line", unpack(shape_verts))

	-- 4. Draw Ember Spark Particles
	local mid_fuse_x = (top_split_x + bot_split_x) * 0.5
	local mid_fuse_y = y + h * 0.5
	for _, s in ipairs(M.sparks) do
		local sx = mid_fuse_x + s.x
		local sy = mid_fuse_y + s.y
		love.graphics.setColor(s.color[1], s.color[2], s.color[3], s.alpha)
		love.graphics.circle("fill", sx, sy, s.size)
	end

	-- 5. Draw center label (countdown or score progress)
	local count_str = M.is_progress_mode()
		and M.format_progress_label()
		or M.format_time(M.time_remaining)
	local font_px = math.max(16, h * 0.62)
	local font = timer_font(font_px)

	if font then
		love.graphics.setFont(font)
		local tw = font:getWidth(count_str)
		local th = font:getHeight()
		local text_cx = x + (w - slant * 0.5) * 0.5
		local text_cy = y + h * 0.5

		-- Text Drop Shadows / Outline for crystal clarity over both green and red backgrounds
		love.graphics.setColor(0.04, 0.06, 0.12, 0.90)
		for ox = -1.5, 1.5, 1.5 do
			for oy = -1.5, 1.5, 1.5 do
				if ox ~= 0 or oy ~= 0 then
					love.graphics.print(count_str, text_cx - tw * 0.5 + ox, text_cy - th * 0.5 + oy + 0.5)
				end
			end
		end

		-- Extra bottom shadow
		love.graphics.setColor(0.02, 0.03, 0.06, 0.85)
		love.graphics.print(count_str, text_cx - tw * 0.5 + 1.5, text_cy - th * 0.5 + 2.0)

		-- Main Text Color
		if M.is_progress_mode() and (M.goal_reached or M.frozen_for_reward) then
			local pulse = math.abs(math.sin(((G.TIMERS and G.TIMERS.REAL) or 0) * 6))
			love.graphics.setColor(1.0, 0.95 - pulse * 0.2, 0.55 - pulse * 0.15, 1)
		elseif not M.is_progress_mode() and M.time_remaining <= 10 and M.time_remaining > 0 then
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
