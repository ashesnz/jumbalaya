--[[
	word_game/ui/perks/timeline_timer/init.lua - Timeline HUD (timer fuse or classic score slider).

	Time Run: burning fuse countdown (60s → 0).
	Classic: score progress bar toward the stage target (dice-have-no-eyes style).
]]

local StageLabel = require("word_game.ui.stage_label")
local RunMode = require("word_game.model.run_mode")
local timer_layout = require("word_game.ui.perks.timeline_timer.layout")
local timer_draw = require("word_game.ui.perks.timeline_timer.draw")

local clamp01 = timer_layout.clamp01

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
M.intro_visible = 1
M.intro_anim = nil
M.countdown_override = false

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

-- Formats the countdown timer text:
-- Whole number (>= 10s), 1 decimal point (< 10s and >= 5s), 2 decimal points (< 5s).
function M.is_progress_mode()
	if M.countdown_override then return false end
	return RunMode.is_classic()
end

local function reset_intro_visibility()
	M.intro_visible = 1
	M.intro_anim = nil
	M.countdown_override = false
end

local function ease_out_cubic(t)
	t = clamp01(t)
	local inv = 1 - t
	return 1 - inv * inv * inv
end

function M.animate_intro(to, duration, on_done)
	duration = duration or 0.4
	local from = M.intro_visible
	if from == nil then from = 1 end
	if duration <= 0 then
		M.intro_anim = nil
		M.intro_visible = to
		if on_done then on_done() end
		return
	end
	M.intro_anim = {
		from = from,
		to = to,
		t = 0,
		dur = duration,
		on_done = on_done,
	}
end

function M.hide_slider(duration, on_done)
	M.pause()
	M.animate_intro(0, duration or 0.42, on_done)
end

--- Switch the HUD to a paused 60s fuse, hidden until `reveal_countdown_timer`.
function M.arm_boss_countdown(duration)
	M.countdown_override = true
	M.TOTAL_DURATION = duration or 60.0
	M.time_remaining = M.TOTAL_DURATION
	M.is_active = false
	M.frozen_for_reward = false
	M.sparks = {}
	M.progress_score = 0
	M.progress_pending = 0
	M.display_frac = 1
	M.display_goal_frac = 1
	M.goal_reached = false
	M.post_target_scoring = false
	M.post_target_pulse = 0
	M.puzzle_word_count = 0
	M.smoke_active = false
	M.slide_boost_t = 0
	M.display_combo = 0
	M.score_roll = nil
	M.intro_visible = 0
	M.intro_anim = nil
	StageLabel.sync()
end

function M.reveal_countdown_timer(duration, on_done)
	M.resume()
	M.animate_intro(1, duration or 0.48, on_done)
end

local function update_intro_anim(dt)
	local anim = M.intro_anim
	if not anim then return end
	anim.t = (anim.t or 0) + (dt or 0)
	local u = ease_out_cubic(anim.t / math.max(0.001, anim.dur or 0.4))
	M.intro_visible = anim.from + (anim.to - anim.from) * u
	if anim.t >= (anim.dur or 0) then
		M.intro_visible = anim.to
		local done = anim.on_done
		M.intro_anim = nil
		if done then done() end
	end
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
	return timer_layout.format_progress_label(M)
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
	return timer_layout.format_time(M, time_val)
end

function M.build_shape_polygon(x, y, w, h, slant, r, n_arc)
	return timer_layout.build_shape_polygon(x, y, w, h, slant, r, n_arc)
end

function M.build_green_polygon(x, y, w, h, slant, r, frac, n_arc)
	return timer_layout.build_green_polygon(x, y, w, h, slant, r, frac, n_arc)
end

function M.reset(duration)
	reset_intro_visibility()
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
	reset_intro_visibility()
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

function M.update(dt)
	dt = dt or 0
	update_intro_anim(dt)
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
				color = math.random() < 0.5 and timer_layout.SPARK_CORE or timer_layout.SPARK_GLOW,
			})
		end
	end
end

function M.draw()
	timer_draw.draw(M, timer_layout)
end

local function register_updater()
	local Updaters = require("app.core.session.updaters")
	Updaters.register("early_board", "timeline_timer", function(game, dt)
		if game.STATE == game.STATES.TABLE_BOARD and WORD_GAME and WORD_GAME.TimelineTimer then
			WORD_GAME.TimelineTimer.update(dt)
		end
	end)
end

register_updater()

return M
