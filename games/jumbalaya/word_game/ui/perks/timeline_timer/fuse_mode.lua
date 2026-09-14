--[[ word_game/ui/perks/timeline_timer/fuse_mode.lua - Time Run fuse countdown HUD ]]

local facade = require("word_game.ui.facade")
local Timeline = facade.timeline()
local game_access = facade.game_access()
local timer_layout = require("word_game.ui.perks.timeline_timer.layout")

local clamp01 = timer_layout.clamp01

local M = {}

function M.apply(Timer)
	function Timer.sync_from_model()
		local g = game_access.get()
		if not g then return end
		if g.timeline_duration then
			Timer.TOTAL_DURATION = g.timeline_duration
		end
		if g.timeline_seconds ~= nil then
			Timer.time_remaining = g.timeline_seconds
		end
		if g.timeline_active ~= nil then
			Timer.is_active = g.timeline_active
		end
		if g.timeline_frozen ~= nil then
			Timer.frozen_for_reward = g.timeline_frozen
		end
		Timer.countdown_override = g.timeline_boss_override == true
	end

	function Timer.pause()
		if Timeline then
			Timeline.pause()
		end
		Timer.sync_from_model()
	end

	function Timer.resume()
		if Timeline then
			Timeline.resume()
		end
		Timer.sync_from_model()
	end

	function Timer.freeze_reward_display(token_amount)
		token_amount = math.max(0, math.floor(token_amount or 0))
		if Timer.is_progress_mode() then
			Timer.progress_score = token_amount
			Timer.progress_pending = 0
			Timer.display_frac = clamp01(token_amount / math.max(1, Timer.progress_target or 1))
			Timer.display_goal_frac = Timer.progress_goal_marker_fraction() or 1
			Timer.goal_reached = token_amount >= (Timer.progress_target or 1)
			Timer.is_active = false
			Timer.frozen_for_reward = true
			Timer.mirror_classic_to_game()
		else
			if Timeline then
				Timeline.freeze(token_amount)
			end
			Timer.sync_from_model()
		end
	end

	function Timer.set_time(time_seconds)
		if Timeline and game_access.get() then
			local cap = game_access.get().timeline_duration or Timer.TOTAL_DURATION
			game_access.patch({ timeline_seconds = math.max(0, math.min(cap, time_seconds or cap)) })
			Timer.sync_from_model()
		else
			Timer.time_remaining = math.max(0, math.min(Timer.TOTAL_DURATION, time_seconds or Timer.TOTAL_DURATION))
		end
	end

	function Timer.add_time(seconds)
		if Timeline then
			Timeline.add_seconds(seconds)
			Timer.sync_from_model()
		else
			seconds = seconds or 0
			if seconds == 0 then return end
			Timer.time_remaining = math.max(0, math.min(Timer.TOTAL_DURATION, Timer.time_remaining + seconds))
		end
	end

	function Timer.fuse_spark_active()
		return Timer.time_remaining > 0 and Timer.time_remaining < Timer.TOTAL_DURATION
	end

	function Timer.spawn_fuse_spark(timer_layout_mod)
		if #Timer.sparks < 25 and math.random() < 0.65 then
			table.insert(Timer.sparks, {
				x = (math.random() - 0.5) * 10,
				y = (math.random() - 0.5) * 6,
				vx = (math.random() - 0.5) * 35,
				vy = -math.random(20, 65),
				size = math.random(2, 5),
				age = 0,
				life = 0.25 + math.random() * 0.35,
				alpha = 1,
				color = math.random() < 0.5 and timer_layout_mod.SPARK_CORE or timer_layout_mod.SPARK_GLOW,
			})
		end
	end
end

return M
