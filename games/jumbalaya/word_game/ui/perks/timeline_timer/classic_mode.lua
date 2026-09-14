--[[ word_game/ui/perks/timeline_timer/classic_mode.lua - Classic score slider HUD ]]

local facade = require("word_game.ui.facade")
local Timeline = facade.timeline()
local game_access = facade.game_access()
local RunMode = facade.run_mode()
local StageLabel = require("word_game.ui.score_banner.stage_label")
local timer_layout = require("word_game.ui.perks.timeline_timer.layout")

local clamp01 = timer_layout.clamp01

local M = {}

function M.apply(Timer, deps)
	local RunMode = deps.RunMode

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
		return combo_level(Timer.puzzle_word_count)
	end

	local function display_combo_level()
		return Timer.display_combo or 0
	end

	function Timer.is_progress_mode()
		if Timer.countdown_override then return false end
		return RunMode.is_classic()
	end

	function Timer.combo_level()
		return target_combo_level()
	end

	function Timer.display_combo_level()
		return display_combo_level()
	end

	function Timer.smoke_glow_scale()
		return glow_scale_for(target_combo_level())
	end

	function Timer.display_smoke_glow_scale()
		return glow_scale_for(display_combo_level())
	end

	function Timer.smoke_spawn_chance()
		return spawn_chance_for(target_combo_level())
	end

	function Timer.display_smoke_spawn_chance()
		return spawn_chance_for(display_combo_level())
	end

	function Timer.smoke_particle_cap()
		return particle_cap_for(target_combo_level())
	end

	function Timer.display_smoke_particle_cap()
		return particle_cap_for(display_combo_level())
	end

	function Timer.shake_strength()
		if not Timer.is_progress_mode() or Timer.frozen_for_reward then return 0 end
		return shake_for_combo(target_combo_level())
	end

	function Timer.display_shake_strength()
		if not Timer.is_progress_mode() or Timer.frozen_for_reward then return 0 end
		return shake_for_combo(display_combo_level())
	end

	function Timer.update_display_intensity(dt)
		if not Timer.is_progress_mode() then
			Timer.display_combo = 0
			return
		end
		local target = target_combo_level()
		if target > Timer.display_combo then
			Timer.display_combo = Timer.display_combo + (target - Timer.display_combo) * math.min(1, dt * COMBO_RISE_SPEED)
		elseif target < Timer.display_combo then
			Timer.display_combo = Timer.display_combo + (target - Timer.display_combo) * math.min(1, dt * COMBO_FALL_SPEED)
		end
		if target == 0 and Timer.display_combo < 0.02 then
			Timer.display_combo = 0
		end
	end

	function Timer.mirror_classic_to_game()
		if not game_access.get() then return end
		if not Timer.is_progress_mode() then return end
		game_access.patch({
			timeline_goal_reached = Timer.goal_reached == true,
			timeline_progress_target = Timer.progress_target,
		})
	end

	function Timer.sync_progress()
		if not Timer.is_progress_mode() then return end
		if Timer.frozen_for_reward or Timer.score_roll then return end
		local wr = game_access.word_round()
		local j = wr and wr.jumble
		local target = math.max(1, (wr and wr.target) or Timer.progress_target or 1)
		local banked = (j and j.total_score) or 0
		local pending = 0
		if j and (j.puzzle_points or 0) > 0 then
			pending = math.floor((j.puzzle_points or 0) * (j.puzzle_multi or 1))
		end
		Timer.progress_target = target
		Timer.progress_score = banked
		Timer.progress_pending = pending
		Timer.puzzle_word_count = #(j and j.puzzle_words or {})
		Timer.smoke_active = Timer.puzzle_word_count >= SMOKE_WORD_THRESHOLD
		Timer.goal_reached = (banked + pending) >= target
		Timer.post_target_scoring = Timer.goal_reached
		Timer.mirror_classic_to_game()
	end

	function Timer.pulse_post_target()
		Timer.post_target_pulse = 1
	end

	function Timer.progress_score_total()
		return (Timer.progress_score or 0) + (Timer.progress_pending or 0)
	end

	function Timer.progress_total_fraction()
		local target = math.max(1, Timer.progress_target or 1)
		local score = Timer.progress_score_total()
		if score >= target then
			return 1
		end
		return clamp01(score / target)
	end

	function Timer.progress_goal_marker_fraction()
		if not Timer.goal_reached then return nil end
		local target = math.max(1, Timer.progress_target or 1)
		local score = math.max(target, Timer.progress_score_total())
		return clamp01(target / score)
	end

	function Timer.display_goal_marker_fraction()
		return Timer.display_goal_frac or 1
	end

	function Timer.on_word_played(_old_total, _new_total)
		if not Timer.is_progress_mode() or Timer.frozen_for_reward then return end
		Timer.sync_progress()
		local target = target_combo_level()
		if target > Timer.display_combo then
			Timer.display_combo = target
		end
		Timer.slide_boost_t = 0.4
	end

	function Timer.reset_puzzle_smoke()
		Timer.slide_boost_t = 0
	end

	function Timer.format_progress_label()
		return timer_layout.format_progress_label(Timer)
	end

	function Timer.progress_fill_fraction()
		local target = math.max(1, Timer.progress_target or 1)
		local score = Timer.progress_score or 0
		return clamp01(score / target)
	end

	function Timer.progress_pending_fraction()
		local target = math.max(1, Timer.progress_target or 1)
		local score = Timer.progress_score or 0
		local pending = Timer.progress_pending or 0
		if pending <= 0 then return 0, Timer.progress_fill_fraction() end
		local from_frac = clamp01(score / target)
		local to_frac = clamp01((score + pending) / target)
		return from_frac, to_frac
	end

	function Timer.reset_progress(target)
		Timer._reset_intro_visibility()
		if Timeline then
			Timeline.clear_boss_override()
		end
		Timer.is_active = false
		Timer.frozen_for_reward = false
		Timer.score_roll = nil
		Timer.sparks = {}
		Timer.progress_target = math.max(1, target or 1)
		Timer.progress_score = 0
		Timer.progress_pending = 0
		Timer.display_frac = 0
		Timer.display_goal_frac = 1
		Timer.goal_reached = false
		Timer.post_target_scoring = false
		Timer.post_target_pulse = 0
		Timer.puzzle_word_count = 0
		Timer.smoke_active = false
		Timer.slide_boost_t = 0
		Timer.display_combo = 0
		Timer.sync_progress()
		Timer.mirror_classic_to_game()
		StageLabel.sync()
		if WORD_GAME_UI.SidebarStageButton and WORD_GAME_UI.SidebarStageButton.reset then
			WORD_GAME_UI.SidebarStageButton.reset()
		end
	end

	function Timer.start_score_roll(from, to, duration)
		from = math.max(0, math.floor(from or 0))
		to = math.max(0, math.floor(to or 0))
		duration = duration or 0.75
		Timer.progress_score = from
		Timer.progress_pending = 0
		Timer.display_frac = clamp01(from / math.max(1, Timer.progress_target or 1))
		Timer.display_goal_frac = Timer.progress_goal_marker_fraction() or 1
		Timer.goal_reached = from >= (Timer.progress_target or 1)
		Timer.is_active = false
		Timer.frozen_for_reward = true
		Timer.score_roll = { from = from, to = to, t = 0, dur = duration }
	end

	function Timer.update_classic(dt)
		if not Timer.is_progress_mode() then return end
		if Timer.score_roll then
			local roll = Timer.score_roll
			roll.t = roll.t + dt
			local u = deps.ease_out_cubic(roll.t / roll.dur)
			local val = roll.from + (roll.to - roll.from) * u
			Timer.progress_score = val
			Timer.progress_pending = 0
			local target = math.max(1, Timer.progress_target or 1)
			Timer.display_frac = clamp01(val / target)
			if Timer.goal_reached then
				Timer.display_goal_frac = clamp01(target / math.max(target, val))
			end
			if roll.t >= roll.dur then
				Timer.progress_score = roll.to
				Timer.score_roll = nil
			end
		elseif not Timer.frozen_for_reward then
			Timer.sync_progress()
		end
		local target_frac = Timer.progress_total_fraction()
		local goal_frac = Timer.progress_goal_marker_fraction() or 1
		local boost = (Timer.slide_boost_t or 0) > 0 and 10 or 0
		if Timer.slide_boost_t and Timer.slide_boost_t > 0 then
			Timer.slide_boost_t = math.max(0, Timer.slide_boost_t - dt)
		end
		if Timer.post_target_pulse and Timer.post_target_pulse > 0 then
			Timer.post_target_pulse = math.max(0, Timer.post_target_pulse - dt * 2.4)
		end
		local lerp_speed = (Timer.frozen_for_reward and 12 or 8) + boost
		Timer.display_frac = Timer.display_frac + (target_frac - Timer.display_frac) * math.min(1, dt * lerp_speed)
		Timer.display_goal_frac = Timer.display_goal_frac + (goal_frac - Timer.display_goal_frac) * math.min(1, dt * lerp_speed)
		Timer.update_display_intensity(dt)
	end

	function Timer.classic_spark_active()
		return Timer.display_combo_level() > 0.04
			and Timer.display_frac > 0.001
			and Timer.display_frac < 0.999
	end

	function Timer.spawn_classic_spark(timer_layout_mod)
		local level = Timer.display_combo_level()
		local cap = Timer.display_smoke_particle_cap()
		local chance = Timer.display_smoke_spawn_chance()
		if #Timer.sparks < cap and math.random() < chance then
			local size_boost = level * 0.55
			local speed_boost = level * 8
			table.insert(Timer.sparks, {
				x = (math.random() - 0.5) * (10 + level * 4),
				y = (math.random() - 0.5) * (6 + level * 2),
				vx = (math.random() - 0.5) * (35 + speed_boost),
				vy = -math.random(20 + level * 6, 65 + level * 12),
				size = math.random(2, 5) + size_boost,
				age = 0,
				life = 0.25 + math.random() * (0.35 + level * 0.08),
				alpha = 1,
				color = math.random() < 0.5 and timer_layout_mod.SPARK_CORE or timer_layout_mod.SPARK_GLOW,
			})
		end
	end
end

return M
