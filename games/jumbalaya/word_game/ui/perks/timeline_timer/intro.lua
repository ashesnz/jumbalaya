local facade = require("word_game.ui.facade")
local Timeline = facade.timeline()
--[[ word_game/ui/perks/timeline_timer/intro.lua - Countdown intro scale animation ]]

local StageLabel = require("word_game.ui.score_banner.stage_label")
local timer_layout = require("word_game.ui.perks.timeline_timer.layout")

local clamp01 = timer_layout.clamp01

return function(M, deps)
	local sync_from_model = deps.sync_from_model

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

	function M.arm_boss_countdown(duration)
		if Timeline then
			Timeline.arm_boss(duration or 60.0)
		end
		sync_from_model()
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

	function M.update_intro_anim(dt)
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

	M._reset_intro_visibility = reset_intro_visibility
end
