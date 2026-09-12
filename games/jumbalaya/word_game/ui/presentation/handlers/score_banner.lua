--[[ word_game/ui/presentation/handlers/score_banner.lua - Score banner and stage label hooks ]]

local M = {}

function M.register(Presentation, ctx)
	local ui = ctx.ui
	local PresentationBus = ctx.Presentation

	Presentation.on("score_banner_reset", function(target)
		if ui.ScoreBanner and ui.ScoreBanner.reset then
			ui.ScoreBanner.reset(target)
		end
	end)

	Presentation.on("score_banner_snap", function()
		if ui.ScoreBanner and ui.ScoreBanner.snap_to_actual then
			ui.ScoreBanner.snap_to_actual()
		end
	end)

	Presentation.on("score_banner_reset_jumble", function()
		if ui.ScoreBanner and ui.ScoreBanner.reset_jumble_score then
			ui.ScoreBanner.reset_jumble_score()
		end
	end)

	Presentation.on("score_banner_set_mode", function(mode, label)
		if ui.ScoreBanner and ui.ScoreBanner.set_banner_mode then
			ui.ScoreBanner.set_banner_mode(mode, label)
		end
	end)

	Presentation.on("score_banner_hide_points", function()
		if ui.ScoreBanner and ui.ScoreBanner.hide_points_to_get_display then
			ui.ScoreBanner.hide_points_to_get_display()
		end
	end)

	Presentation.on("score_banner_sync_preview", function(enabled)
		if ui.ScoreBanner and ui.ScoreBanner.sync_points_to_get_preview then
			ui.ScoreBanner.sync_points_to_get_preview(enabled)
		end
	end)

	Presentation.on("score_banner_jumble_hand_start", function()
		if not ui.ScoreBanner then return end
		if not ui.ScoreBanner.state then return end
		local hud = ui.ScoreBanner.state()
		hud.to_go_label = "SCORE"
		hud.target = 0
		hud.remaining = 0
		if ui.ScoreBanner.reset_jumble_score then
			ui.ScoreBanner.reset_jumble_score()
		end
	end)

	Presentation.on("stage_label_sync", function()
		if ui.StageLabel and ui.StageLabel.sync then
			ui.StageLabel.sync()
		end
	end)

	Presentation.on("stage_label_force_sync", function()
		if ui.StageLabel and ui.StageLabel.force_sync then
			ui.StageLabel.force_sync()
		end
	end)

	Presentation.on("jumble_hud_refresh", function()
		if ui.ScoreBanner and ui.ScoreBanner.snap_to_actual then
			ui.ScoreBanner.snap_to_actual()
		end
	end)

	Presentation.on("PLAY_RESOLVED", function(result)
		if not result or result.kind == "invalid" then return end
		if ui.ScoreBanner and ui.ScoreBanner.sync_points_to_get_preview then
			ui.ScoreBanner.sync_points_to_get_preview(true)
		end
		PresentationBus.emit("jumble_hud_refresh")
	end)
end

return M
