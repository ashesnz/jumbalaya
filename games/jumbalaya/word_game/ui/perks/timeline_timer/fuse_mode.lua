--[[ word_game/ui/perks/timeline_timer/fuse_mode.lua - Time Run fuse countdown HUD ]]

local facade = require("word_game.ui.facade")
local game_access = facade.game_access()
local timer_layout = require("word_game.ui.perks.timeline_timer.layout")

local clamp01 = timer_layout.clamp01

return function(M)
	function M.sync_from_model()
		local g = game_access.get()
		if not g then return end
		if g.timeline_duration then
			M.TOTAL_DURATION = g.timeline_duration
		end
		if g.timeline_seconds ~= nil then
			M.time_remaining = g.timeline_seconds
		end
		if g.timeline_active ~= nil then
			M.is_active = g.timeline_active
		end
		if g.timeline_frozen ~= nil then
			M.frozen_for_reward = g.timeline_frozen
		end
		M.countdown_override = g.timeline_boss_override == true
	end

	function M.pause()
		if WORD_GAME and WORD_GAME.Timeline then
			WORD_GAME.Timeline.pause()
		end
		M.sync_from_model()
	end

	function M.resume()
		if WORD_GAME and WORD_GAME.Timeline then
			WORD_GAME.Timeline.resume()
		end
		M.sync_from_model()
	end

	function M.freeze_reward_display(token_amount)
		token_amount = math.max(0, math.floor(token_amount or 0))
		if M.is_progress_mode() then
			M.progress_score = token_amount
			M.progress_pending = 0
			M.display_frac = clamp01(token_amount / math.max(1, M.progress_target or 1))
			M.display_goal_frac = M.progress_goal_marker_fraction() or 1
			M.goal_reached = token_amount >= (M.progress_target or 1)
			M.is_active = false
			M.frozen_for_reward = true
			M.mirror_classic_to_game()
		else
			if WORD_GAME and WORD_GAME.Timeline then
				WORD_GAME.Timeline.freeze(token_amount)
			end
			M.sync_from_model()
		end
	end

	function M.set_time(time_seconds)
		if WORD_GAME and WORD_GAME.Timeline and game_access.get() then
			local cap = game_access.get().timeline_duration or M.TOTAL_DURATION
			game_access.patch({ timeline_seconds = math.max(0, math.min(cap, time_seconds or cap)) })
			M.sync_from_model()
		else
			M.time_remaining = math.max(0, math.min(M.TOTAL_DURATION, time_seconds or M.TOTAL_DURATION))
		end
	end

	function M.add_time(seconds)
		if WORD_GAME and WORD_GAME.Timeline then
			WORD_GAME.Timeline.add_seconds(seconds)
			M.sync_from_model()
		else
			seconds = seconds or 0
			if seconds == 0 then return end
			M.time_remaining = math.max(0, math.min(M.TOTAL_DURATION, M.time_remaining + seconds))
		end
	end

	function M.fuse_spark_active()
		return M.time_remaining > 0 and M.time_remaining < M.TOTAL_DURATION
	end

	function M.spawn_fuse_spark(timer_layout_mod)
		if #M.sparks < 25 and math.random() < 0.65 then
			table.insert(M.sparks, {
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
