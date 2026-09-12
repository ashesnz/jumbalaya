--[[ word_game/ui/perks/timeline_timer/classic_mode.lua - Classic score slider HUD ]]

local facade = require("word_game.ui.facade")
local game_access = facade.game_access()
local RunMode = facade.run_mode()
local StageLabel = require("word_game.ui.score_banner.stage_label")
local timer_layout = require("word_game.ui.perks.timeline_timer.layout")

local clamp01 = timer_layout.clamp01

return function(M, deps)
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
		return combo_level(M.puzzle_word_count)
	end

	local function display_combo_level()
		return M.display_combo or 0
	end

	function M.is_progress_mode()
		if M.countdown_override then return false end
		return RunMode.is_classic()
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

	function M.mirror_classic_to_game()
		if not game_access.get() then return end
		if not M.is_progress_mode() then return end
		game_access.patch({
			timeline_goal_reached = M.goal_reached == true,
			timeline_progress_target = M.progress_target,
		})
	end

	function M.sync_progress()
		if not M.is_progress_mode() then return end
		if M.frozen_for_reward or M.score_roll then return end
		local wr = game_access.word_round()
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
		M.mirror_classic_to_game()
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

	function M.reset_progress(target)
		M._reset_intro_visibility()
		if WORD_GAME and WORD_GAME.Timeline then
			WORD_GAME.Timeline.clear_boss_override()
		end
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
		M.mirror_classic_to_game()
		StageLabel.sync()
		if WORD_GAME_UI.SidebarStageButton and WORD_GAME_UI.SidebarStageButton.reset then
			WORD_GAME_UI.SidebarStageButton.reset()
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

	function M.update_classic(dt)
		if not M.is_progress_mode() then return end
		if M.score_roll then
			local roll = M.score_roll
			roll.t = roll.t + dt
			local u = deps.ease_out_cubic(roll.t / roll.dur)
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
	end

	function M.classic_spark_active()
		return M.display_combo_level() > 0.04
			and M.display_frac > 0.001
			and M.display_frac < 0.999
	end

	function M.spawn_classic_spark(timer_layout_mod)
		local level = M.display_combo_level()
		local cap = M.display_smoke_particle_cap()
		local chance = M.display_smoke_spawn_chance()
		if #M.sparks < cap and math.random() < chance then
			local size_boost = level * 0.55
			local speed_boost = level * 8
			table.insert(M.sparks, {
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
