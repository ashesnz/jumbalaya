--[[ word_game/ui/presentation/install.lua - Register model→UI presentation hooks at boot ]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local Presentation = require("word_game.model.presentation")
local LayoutRequest = require("word_game.model.layout.request")
local round_config = require("word_game.config.gameplay.round")
local RunMode = require("word_game.model.run.mode")
local game_access = require("word_game.model.game_access")

local M = {}

function M.install(ui, domain)
	Presentation.clear()
	ui = ui or rawget(_G, "WORD_GAME_UI") or {}
	domain = domain or rawget(_G, "WORD_GAME") or {}
	local Layout = ui.Layout
	local Scheduler = require("app.effects.timeline_scheduler")
	local backgrounds = require("word_game.ui.layout.backgrounds")
	local CardFocus = require("app.core.input.card_focus")
	local TableAreas = require("word_game.model.table_areas")
local Funcs = require("bridge.funcs_registry")

	CardFocus.install({
		hand_area = TableAreas.dealt_letters,
		bonus_stack_contains = function(node)
			return ui.BonusStackUI and ui.BonusStackUI.contains(node)
		end,
	})

	runtime().notify_display_changed = function()
		if runtime().STAGE == runtime().STAGES.RUN and ui.Sidebar then
			ui.Sidebar.rebuild()
		end
	end

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
		if ui.Sidebar then
			ui.Sidebar:refresh()
		end
	end)

	Presentation.on("sidebar_ensure", function()
		if ui.Sidebar then
			ui.Sidebar:ensure()
		end
	end)

	Presentation.on("sidebar_clear_hand", function()
		if ui.Sidebar and ui.Sidebar.clear_hand then
			ui.Sidebar:clear_hand()
		end
	end)

	Presentation.on("sidebar_sync_visibility", function()
		if ui.Sidebar and ui.Sidebar.sync_visibility then
			ui.Sidebar.sync_visibility()
		end
	end)

	Presentation.on("hand_shuffle_sync_position", function()
		if ui.TableControls and ui.TableControls.sync_position then
			ui.TableControls.sync_position()
		end
	end)

	Presentation.on("layout_refresh_placement", function()
		if Layout and Layout.refresh_placement_layout then
			Layout.refresh_placement_layout()
		elseif runtime().pattern_row and runtime().pattern_row.apply_screen_position then
			runtime().pattern_row:apply_screen_position()
		end
	end)

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

	Presentation.on("bonus_stack_on_hand_start", function(set, hand_index)
		if ui.BonusStackUI and ui.BonusStackUI.on_hand_start then
			ui.BonusStackUI.on_hand_start(set, hand_index)
		end
	end)

	Presentation.on("jumble_hud_refresh", function()
		local wr = game_access.word_round()
		local j = wr and wr.jumble
		if not j or not ui.ScoreBanner then return end
		local hud = ui.ScoreBanner.state()
		hud.to_go_label = "SCORE"
		hud.remaining = j.total_score or 0
		if ui.ScoreBanner.sync_points_to_get_preview then
			ui.ScoreBanner.sync_points_to_get_preview(false)
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
		if ui.PlayEffects and ui.PlayEffects.present_boss_word then
			ui.PlayEffects.present_boss_word(wr, on_complete)
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
		local wr = game_access.word_round()
		if wr then
			Presentation.emit("score_banner_reset", wr.target)
		end
		local jumble = domain.Jumble
		if jumble and jumble.is_active_hand(set, hand_index) then
			Presentation.emit("timeline_reset")
		end
		Presentation.emit("sidebar_clear_hand")
		Presentation.emit("stage_label_sync")
		Presentation.emit("sidebar_refresh")
		Presentation.emit("stage_backgrounds", set, hand_index)
	end)

	Presentation.on("hand_shuffle_sync", function()
		if ui.TableControls and ui.TableControls.sync then
			ui.TableControls.sync()
		end
	end)

	Presentation.on("voucher_discard_ui_reset", function()
		if ui.VoucherDiscard and ui.VoucherDiscard.reset then
			ui.VoucherDiscard.reset()
		end
	end)

	Presentation.on("voucher_discard_recorded", function(from_left, to_left)
		local vd = ui.VoucherDiscard
		if not vd then return end
		if vd.roll_discards_left then
			vd.roll_discards_left(from_left, to_left)
		end
		if vd.sync_sidebar_ui then
			vd.sync_sidebar_ui()
		end
	end)

	Presentation.on("voucher_discard_ui_sync", function()
		if ui.VoucherDiscard and ui.VoucherDiscard.sync_sidebar_ui then
			ui.VoucherDiscard.sync_sidebar_ui()
		end
	end)

	Presentation.on("table_deck_reset", function()
		if ui.TableDeck and ui.TableDeck.reset then
			ui.TableDeck.reset()
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
		if overlay_def and runtime().FUNCS and runtime().FUNCS.show_overlay then
			runtime().FUNCS.show_overlay{
				definition = overlay_def,
				config = { no_esc = true },
			}
		end
	end)

	Presentation.on("run_board_ready", function()
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
