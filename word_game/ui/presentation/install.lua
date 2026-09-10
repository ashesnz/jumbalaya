--[[ word_game/ui/presentation/install.lua - Register model→UI presentation hooks at boot ]]

local Presentation = require("word_game.model.presentation")
local LayoutRequest = require("word_game.model.layout.request")
local round_config = require("word_game.config.gameplay.round")
local RunMode = require("word_game.model.run.mode")

local M = {}

function M.install(word_game)
	Presentation.clear()
	local Layout = word_game.Layout
	local backgrounds = require("word_game.ui.layout.backgrounds")

	Presentation.on("layout_refresh", function()
		LayoutRequest.refresh()
	end)

	Presentation.on("run_backgrounds", function()
		backgrounds.run()
		LayoutRequest.refresh()
	end)

	Presentation.on("stage_backgrounds", function(set, hand_index)
		backgrounds.stage(set, hand_index)
	end)

	Presentation.on("sidebar_refresh", function()
		if word_game.Sidebar then
			word_game.Sidebar:refresh()
		end
	end)

	Presentation.on("sidebar_ensure", function()
		if word_game.Sidebar then
			word_game.Sidebar:ensure()
		end
	end)

	Presentation.on("sidebar_clear_hand", function()
		if word_game.Sidebar and word_game.Sidebar.clear_hand then
			word_game.Sidebar:clear_hand()
		end
	end)

	Presentation.on("sidebar_sync_visibility", function()
		if word_game.Sidebar and word_game.Sidebar.sync_visibility then
			word_game.Sidebar.sync_visibility()
		end
	end)

	Presentation.on("hand_shuffle_sync_position", function()
		if word_game.HandShuffle and word_game.HandShuffle.sync_position then
			word_game.HandShuffle.sync_position()
		end
	end)

	Presentation.on("layout_refresh_placement", function()
		if Layout and Layout.refresh_placement_layout then
			Layout.refresh_placement_layout()
		elseif G.placement_table and G.placement_table.apply_screen_position then
			G.placement_table:apply_screen_position()
		end
	end)

	Presentation.on("score_banner_reset", function(target)
		if word_game.ScoreBanner and word_game.ScoreBanner.reset then
			word_game.ScoreBanner.reset(target)
		end
	end)

	Presentation.on("score_banner_snap", function()
		if word_game.ScoreBanner and word_game.ScoreBanner.snap_to_actual then
			word_game.ScoreBanner.snap_to_actual()
		end
	end)

	Presentation.on("score_banner_reset_jumble", function()
		if word_game.ScoreBanner and word_game.ScoreBanner.reset_jumble_score then
			word_game.ScoreBanner.reset_jumble_score()
		end
	end)

	Presentation.on("score_banner_set_mode", function(mode, label)
		if word_game.ScoreBanner and word_game.ScoreBanner.set_banner_mode then
			word_game.ScoreBanner.set_banner_mode(mode, label)
		end
	end)

	Presentation.on("score_banner_hide_points", function()
		if word_game.ScoreBanner and word_game.ScoreBanner.hide_points_to_get_display then
			word_game.ScoreBanner.hide_points_to_get_display()
		end
	end)

	Presentation.on("score_banner_sync_preview", function(enabled)
		if word_game.ScoreBanner and word_game.ScoreBanner.sync_points_to_get_preview then
			word_game.ScoreBanner.sync_points_to_get_preview(enabled)
		end
	end)

	Presentation.on("score_banner_jumble_hand_start", function()
		if not word_game.ScoreBanner then return end
		if not word_game.ScoreBanner.state then return end
		local hud = word_game.ScoreBanner.state()
		hud.to_go_label = "SCORE"
		hud.target = 0
		hud.remaining = 0
		if word_game.ScoreBanner.reset_jumble_score then
			word_game.ScoreBanner.reset_jumble_score()
		end
	end)

	Presentation.on("stage_label_sync", function()
		if word_game.StageLabel and word_game.StageLabel.sync then
			word_game.StageLabel.sync()
		end
	end)

	Presentation.on("stage_label_force_sync", function()
		if word_game.StageLabel and word_game.StageLabel.force_sync then
			word_game.StageLabel.force_sync()
		end
	end)

	Presentation.on("timeline_reset", function()
		if not word_game.TimelineTimer then return end
		local wr = G.GAME and G.GAME.word_round
		if RunMode.is_classic() then
			local target = (wr and wr.target) or round_config.hand_target(1, 1)
			if word_game.TimelineTimer.reset_progress then
				word_game.TimelineTimer.reset_progress(target)
			end
			return
		end
		if word_game.TimelineTimer.reset then
			word_game.TimelineTimer.reset(round_config.TIMELINE_SECONDS)
		end
	end)

	Presentation.on("timeline_reset_puzzle_smoke", function()
		if word_game.TimelineTimer and word_game.TimelineTimer.reset_puzzle_smoke then
			word_game.TimelineTimer.reset_puzzle_smoke()
		end
	end)

	Presentation.on("timeline_sync_progress", function()
		if word_game.TimelineTimer and word_game.TimelineTimer.sync_progress then
			word_game.TimelineTimer.sync_progress()
		end
	end)

	Presentation.on("timeline_time_remaining", function()
		local timer = word_game.TimelineTimer
		if timer and timer.time_remaining then
			return timer.time_remaining
		end
	end)

	Presentation.on("timeline_add_time", function(seconds)
		if not seconds or seconds == 0 then return false end
		local timer = word_game.TimelineTimer
		if timer and timer.add_time then
			timer.add_time(seconds)
			return true
		end
		return false
	end)

	Presentation.on("timeline_classic_sync_progress", function()
		local timer = word_game.TimelineTimer
		if not timer or not timer.is_progress_mode or not timer.is_progress_mode() then
			return false
		end
		if timer.sync_progress then
			timer.sync_progress()
		end
		return timer.goal_reached == true
	end)

	Presentation.on("timeline_classic_progress_target", function()
		local timer = word_game.TimelineTimer
		if timer and timer.progress_target then
			return timer.progress_target
		end
	end)

	Presentation.on("bonus_stack_on_hand_start", function(set, hand_index)
		if word_game.BonusStackUI and word_game.BonusStackUI.on_hand_start then
			word_game.BonusStackUI.on_hand_start(set, hand_index)
		end
	end)

	Presentation.on("jumble_hud_refresh", function()
		local j = G.GAME and G.GAME.word_round and G.GAME.word_round.jumble
		if not j or not word_game.ScoreBanner then return end
		local hud = word_game.ScoreBanner.state()
		hud.to_go_label = "SCORE"
		hud.remaining = j.total_score or 0
		if word_game.ScoreBanner.sync_points_to_get_preview then
			word_game.ScoreBanner.sync_points_to_get_preview(false)
		end
		Presentation.emit("timeline_sync_progress")
	end)

	Presentation.on("puzzle_applied", function()
		Presentation.emit("timeline_reset_puzzle_smoke")
		Presentation.emit("timeline_sync_progress")
		Presentation.emit("score_banner_reset_jumble")
	end)

	Presentation.on("boss_puzzle_revealed", function()
		Presentation.emit("layout_refresh_placement")
		Presentation.emit("sidebar_sync_visibility")
		Presentation.emit("hand_shuffle_sync_position")
		Presentation.emit("score_banner_set_mode", "boss_word", "BOSS WORD")
		Presentation.emit("score_banner_hide_points")
	end)

	Presentation.on("boss_word_begin", function(wr, on_complete)
		if word_game.PlayEffects and word_game.PlayEffects.present_boss_word then
			word_game.PlayEffects.present_boss_word(wr, on_complete)
			return true
		end
		return false
	end)

	Presentation.on("round_restore_from_save", function(wr)
		Presentation.emit("score_banner_reset", wr.target)
		Presentation.emit("score_banner_snap")
		Presentation.emit("timeline_reset")
		Presentation.emit("stage_label_force_sync")
		Presentation.emit("sidebar_ensure")
		Presentation.emit("sidebar_refresh")
		Presentation.emit("stage_backgrounds", wr.set, wr.hand_index)
	end)

	Presentation.on("hand_started", function(set, hand_index)
		Presentation.emit("bonus_stack_on_hand_start", set, hand_index)
		local wr = G.GAME and G.GAME.word_round
		if wr then
			Presentation.emit("score_banner_reset", wr.target)
		end
		local jumble = word_game.Jumble
		if jumble and jumble.is_active_hand(set, hand_index) then
			Presentation.emit("timeline_reset")
		end
		Presentation.emit("sidebar_clear_hand")
		Presentation.emit("stage_label_sync")
		Presentation.emit("sidebar_refresh")
		Presentation.emit("stage_backgrounds", set, hand_index)
	end)
end

return M
