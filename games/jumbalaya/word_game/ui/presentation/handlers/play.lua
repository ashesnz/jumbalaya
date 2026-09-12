--[[ word_game/ui/presentation/handlers/play.lua - Hand lifecycle, boss word, and match hooks ]]

local game_access = require("word_game.model.game_access")

local M = {}

function M.register(Presentation, ctx)
	local ui = ctx.ui
	local domain = ctx.domain
	local PresentationBus = ctx.Presentation
	local Funcs = ctx.Funcs

	Presentation.on("puzzle_applied", function()
		PresentationBus.emit("timeline_reset_puzzle_smoke")
		PresentationBus.emit("timeline_sync_progress")
		PresentationBus.emit("score_banner_reset_jumble")
	end)

	Presentation.on("boss_puzzle_revealed", function()
		PresentationBus.emit("layout_refresh_placement")
		PresentationBus.emit("sidebar_sync_visibility")
		PresentationBus.emit("hand_shuffle_sync_position")
		PresentationBus.emit("score_banner_set_mode", "boss_word", "BOSS WORD")
		PresentationBus.emit("score_banner_hide_points")
	end)

	Presentation.on("boss_word_begin", function(wr, on_complete)
		if ui.PlayEffects and ui.PlayEffects.present_boss_word then
			ui.PlayEffects.present_boss_word(wr, on_complete)
			return true
		end
		return false
	end)

	Presentation.on("round_restore_from_save", function(wr)
		PresentationBus.emit("score_banner_reset", wr.target)
		PresentationBus.emit("score_banner_snap")
		PresentationBus.emit("timeline_reset")
		PresentationBus.emit("stage_label_force_sync")
		PresentationBus.emit("sidebar_ensure")
		PresentationBus.emit("sidebar_refresh")
		PresentationBus.emit("stage_backgrounds", wr.set, wr.hand_index)
	end)

	Presentation.on("hand_started", function(set, hand_index)
		PresentationBus.emit("bonus_stack_on_hand_start", set, hand_index)
		local wr = game_access.word_round()
		if wr then
			PresentationBus.emit("score_banner_reset", wr.target)
		end
		local jumble = domain.Jumble
		if jumble and jumble.is_active_hand(set, hand_index) then
			PresentationBus.emit("timeline_reset")
		end
		PresentationBus.emit("sidebar_clear_hand")
		PresentationBus.emit("stage_label_sync")
		PresentationBus.emit("sidebar_refresh")
		PresentationBus.emit("stage_backgrounds", set, hand_index)
	end)

	Presentation.on("bonus_stack_on_hand_start", function(set, hand_index)
		if ui.BonusStackUI and ui.BonusStackUI.on_hand_start then
			ui.BonusStackUI.on_hand_start(set, hand_index)
		end
	end)

	Presentation.on("bonus_card_return", function(card)
		if ui.BonusStackUI and ui.BonusStackUI.return_card then
			return ui.BonusStackUI.return_card(card)
		end
		return false
	end)

	Presentation.on("match_ended", function(won)
		local overlay_def
		if ui.EndMatch and ui.EndMatch.overlay_definition then
			overlay_def = ui.EndMatch.overlay_definition(won)
		elseif type(build_game_over) == "function" then
			overlay_def = build_game_over()
		end
		if overlay_def and Funcs.get("show_overlay") then
			Funcs.dispatch("show_overlay", {
				definition = overlay_def,
				config = { no_esc = true },
			})
		end
	end)

	Presentation.on("run_board_ready", function()
		local Scheduler = ctx.Scheduler
		local runtime = ctx.runtime
		Scheduler.add{
			mode = "delayed",
			delay = 0.45,
			blocking = false,
			func = function()
				if runtime().STATE == runtime().STATES.TABLE_BOARD and runtime().STAGE == runtime().STAGES.RUN then
					if ui.PerkStamp and ui.PerkStamp.try_opening_demo then
						ui.PerkStamp.try_opening_demo()
					end
				end
				return true
			end,
		}
		if ui.FirstPlayTutorial and ui.FirstPlayTutorial.try_schedule then
			ui.FirstPlayTutorial.try_schedule()
		end
	end)
end

return M
