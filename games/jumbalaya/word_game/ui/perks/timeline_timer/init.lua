--[[
	word_game/ui/perks/timeline_timer/init.lua - Timeline HUD coordinator.

	Time Run: burning fuse countdown (60s → 0).
	Classic: score progress bar toward the stage target.
]]

local facade = require("word_game.ui.facade")
local game_access = facade.game_access()
local StageLabel = require("word_game.ui.score_banner.stage_label")
local timer_layout = require("word_game.ui.perks.timeline_timer.layout")
local timer_draw = require("word_game.ui.perks.timeline_timer.draw")

local RunMode = facade.run_mode()
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

local function ease_out_cubic(t)
	t = clamp01(t)
	local inv = 1 - t
	return 1 - inv * inv * inv
end

local deps = {
	RunMode = RunMode,
	sync_from_model = function() M.sync_from_model() end,
	ease_out_cubic = ease_out_cubic,
}

require("word_game.ui.perks.timeline_timer.intro")(M, deps)
require("word_game.ui.perks.timeline_timer.classic_mode")(M, deps)
require("word_game.ui.perks.timeline_timer.fuse_mode")(M, deps)

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
	M._reset_intro_visibility()
	duration = duration or 60.0
	if WORD_GAME and WORD_GAME.Timeline and not M.is_progress_mode() then
		WORD_GAME.Timeline.reset(duration)
		M.sync_from_model()
	else
		M.TOTAL_DURATION = duration
		M.time_remaining = duration
		M.is_active = not M.is_progress_mode()
		M.frozen_for_reward = false
	end
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
	local wr = game_access.word_round()
	M.progress_target = math.max(1, (wr and wr.target) or 1)
	M.sync_progress()
	M.mirror_classic_to_game()
	StageLabel.sync()
	if WORD_GAME_UI.SidebarStageButton and WORD_GAME_UI.SidebarStageButton.reset then
		WORD_GAME_UI.SidebarStageButton.reset()
	end
end

function M.update(dt)
	dt = dt or 0
	M.sync_from_model()
	M.update_intro_anim(dt)
	if M.is_progress_mode() then
		M.update_classic(dt)
	else
		M.sync_from_model()
	end

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

	M.mirror_classic_to_game()
	StageLabel.update(dt)

	local spark_active = M.is_progress_mode() and M.classic_spark_active() or M.fuse_spark_active()
	if spark_active then
		if M.is_progress_mode() then
			M.spawn_classic_spark(timer_layout)
		else
			M.spawn_fuse_spark(timer_layout)
		end
	end
end

function M.draw()
	timer_draw.draw(M, timer_layout)
end

return M
