--[[ word_game/ui/presentation/handlers/timeline.lua - Timeline fuse / classic slider hooks ]]

local round_config = require("jumbalaya_core.config.gameplay.round")
local RunMode = require("word_game.model.run.mode")
local game_access = require("word_game.model.game_access")

local M = {}

function M.register(Presentation, ctx)
	local ui = ctx.ui
	local domain = ctx.domain

	Presentation.on("timeline_reset", function()
		if not ui.TimelineTimer then return end
		local wr = game_access.word_round()
		if RunMode.is_classic() then
			if domain.Timeline and domain.Timeline.clear_boss_override then
				domain.Timeline.clear_boss_override()
			end
			local target = (wr and wr.target) or round_config.hand_target(1, 1)
			if ui.TimelineTimer.reset_progress then
				ui.TimelineTimer.reset_progress(target)
			end
			return
		end
		if domain.Timeline and domain.Timeline.reset then
			domain.Timeline.reset(round_config.TIMELINE_SECONDS)
		elseif ui.TimelineTimer.reset then
			ui.TimelineTimer.reset(round_config.TIMELINE_SECONDS)
		end
	end)

	Presentation.on("timeline_reset_puzzle_smoke", function()
		if ui.TimelineTimer and ui.TimelineTimer.reset_puzzle_smoke then
			ui.TimelineTimer.reset_puzzle_smoke()
		end
	end)

	Presentation.on("timeline_sync_progress", function()
		if ui.TimelineTimer and ui.TimelineTimer.sync_progress then
			ui.TimelineTimer.sync_progress()
		end
	end)

	Presentation.on("timeline_apply_seconds", function()
		if ui.TimelineTimer and ui.TimelineTimer.sync_from_model then
			ui.TimelineTimer.sync_from_model()
		end
	end)

	Presentation.on("timeline_sync_from_model", function()
		if ui.TimelineTimer and ui.TimelineTimer.sync_from_model then
			ui.TimelineTimer.sync_from_model()
		end
	end)
end

return M
