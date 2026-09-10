--[[ word_game/ui/play_effects/definition.lua - Play feedback, banners, and layout sync ]]

local M = {}

local facade = require("word_game.ui.facade")
local word_feedback = require("word_game.ui.feedback.word_feedback")
local function bonus_stack_ui()
	return facade.bonus_stack_ui()
end
local round_config = require("word_game.config.gameplay.round")

local RunMode = facade.run_mode()

M.BOSS_INTRO = {
	hide_duration = 0.42,
	timer_reveal_duration = 0.48,
	steps = {
		{ text = "3", hold = 0.85 },
		{ text = "2", hold = 0.85 },
		{ text = "1", hold = 0.85 },
	},
}

function M.capture_token_timer_if_cleared(cleared, opts)
	opts = opts or {}
	if not cleared or not RunMode.ends_hand_on_target() then return end
	if not opts.skip_focus
		and WORD_GAME_UI.HandClearFocus and WORD_GAME_UI.HandClearFocus.begin then
		WORD_GAME_UI.HandClearFocus.begin()
	end
	if WORD_GAME_UI.TokenReward and WORD_GAME_UI.TokenReward.capture_reward then
		WORD_GAME_UI.TokenReward.capture_reward()
	elseif WORD_GAME_UI.TokenReward and WORD_GAME_UI.TokenReward.capture_timer then
		WORD_GAME_UI.TokenReward.capture_timer()
	end
end

function M.triggers_boss_word(result)
	if not result or not result.cleared then return false end
	local wr = G.GAME and G.GAME.word_round
	local j = wr and wr.jumble
	return wr and round_config.is_boss_word_hand(wr.set, wr.hand_index)
		and j and not j.boss_word_active and not j.boss_word_staging
end

function M.show_post_target_multiplier_fx(result)
	if not result or not result.post_target_doubled then return end
	local tt = WORD_GAME_UI.TimelineTimer
	if tt and tt.pulse_post_target then
		tt.pulse_post_target()
	end
	local FloatUp = WORD_GAME_UI.FloatUpText
	if FloatUp and FloatUp.from_timeline then
		-- Same gold float-up-and-fade as "Hand Cleared", anchored to the slider tip.
		FloatUp.from_timeline("×2", {
			colour = G.C and G.C.GOLD or { 1, 0.85, 0.2, 1 },
			font_px = 32,
			speed = 1.25,
			life = 1.8,
		})
	end
end

function M.roll_jumble_banners(result)
	if not (WORD_GAME_UI.ScoreBanner) then return end
	local function bump_timeline_progress()
		local tt = WORD_GAME_UI.TimelineTimer
		if not tt or not tt.on_word_played or not result then return end
		if result.kind == "word_play" then
			tt.on_word_played(result.old_score, result.new_score)
		elseif result.kind == "bank_puzzle" then
			tt.on_word_played(result.old_total, result.new_total)
		end
	end
	if M.triggers_boss_word(result) then
		if WORD_GAME_UI.ScoreBanner.hide_points_to_get_display then
			WORD_GAME_UI.ScoreBanner.hide_points_to_get_display()
		end
		if result.kind == "word_play" and WORD_GAME_UI.ScoreBanner.roll_jumble_score then
			WORD_GAME_UI.ScoreBanner.roll_jumble_score(
				result.old_pts, result.new_pts, result.old_multi, result.new_multi
			)
		end
		bump_timeline_progress()
		return
	end
	if result.kind == "word_play" then
		if WORD_GAME_UI.ScoreBanner.roll_jumble_score then
			WORD_GAME_UI.ScoreBanner.roll_jumble_score(
				result.old_pts, result.new_pts, result.old_multi, result.new_multi
			)
		end
		M.show_post_target_multiplier_fx(result)
		bump_timeline_progress()
	elseif result.kind == "bank_puzzle" then
		M.show_post_target_multiplier_fx(result)
		bump_timeline_progress()
	end
	if result.cleared and RunMode.ends_hand_on_target() then
		if WORD_GAME_UI.ScoreBanner.hide_points_to_get_display then
			WORD_GAME_UI.ScoreBanner.hide_points_to_get_display()
		end
	elseif WORD_GAME_UI.ScoreBanner.sync_points_to_get_preview then
		WORD_GAME_UI.ScoreBanner.sync_points_to_get_preview(true, { remain_dur = 0.4 })
	end
end

function M.show_validation_error(err)
	if word_feedback.is_invalid_reason(err) then
		word_feedback.show_invalid()
	else
		word_feedback.show(err or "Cannot play", G.C.RED)
	end
	play_sfx("cancel", 0.8, 0.6)
end

function M.set_word_score_animating(active)
	if G.GAME then
		G.GAME.word_score_animating = active
	end
	-- deal_boss_hand and other sequences call set_ranks while this flag is still
	-- true, which leaves drag.can false until ranks are refreshed.
	if not active
		and WORD_GAME_UI.TableInput
		and WORD_GAME_UI.TableInput.refresh_card_input then
		WORD_GAME_UI.TableInput.refresh_card_input()
	end
end

function M.add_points(_amount)
	-- Score is tracked on wr.jumble.total_score by the model; banner syncs via jumble rules.
end

function M.sync_hand_after_deal()
	if G.dealt_letters and G.dealt_letters.cards[1] then
		G.dealt_letters:relayout()
		for _, card in ipairs(G.dealt_letters.cards) do
			if not card.bounce and card.states and not card.states.drag.is then
				card:hard_set_T()
			end
		end
		if G.dealt_letters.velocity then
			G.dealt_letters.velocity.x = 0
			G.dealt_letters.velocity.y = 0
			G.dealt_letters.velocity.r = 0
			G.dealt_letters.velocity.scale = 0
		end
		G.dealt_letters:snap_VT()
	end
	if WORD_GAME_UI.TableControls then
		WORD_GAME_UI.TableControls.sync_position()
	end
end

function M.align_placement_table()
	if G.pattern_row and G.pattern_row.area then
		G.pattern_row:relayout()
		G.pattern_row.area:hard_set_cards()
	end
end

function M.show_word_success(word)
	word_feedback.show(word .. "  +" .. #word, G.C.GREEN, 1.2, 0.35)
	play_sfx("coin2", 1, 0.9)
end

function M.show_puzzle_bank_feedback(puzzle_total)
	word_feedback.show(puzzle_total .. " Points Scored!", G.C.GOLD, 1.5, 0.35)
	play_sfx("coin2", 1, 0.9)
end

function M.sync_hand_controls()
	if WORD_GAME_UI.TableControls then
		WORD_GAME_UI.TableControls.sync()
	end
end

function M.restore_boss_layout(opts)
	opts = opts or {}
	if not opts.keep_bonus_stack then
		bonus_stack_ui().clear()
	end
	local wr = G.GAME and G.GAME.word_round
	if wr and wr.jumble then
		wr.jumble.locked_hand_layout = nil
	end
	if WORD_GAME_UI.Layout then
		WORD_GAME_UI.Layout.update_all()
		WORD_GAME_UI.Layout.set_screen_positions()
	end
	if WORD_GAME_UI.Sidebar and WORD_GAME_UI.Sidebar.sync_visibility then
		WORD_GAME_UI.Sidebar.sync_visibility()
	end
	G.ARGS = G.ARGS or {}
	G.ARGS.pending_layout = true
	M.align_placement_table()
	if G.dealt_letters then
		G.dealt_letters:relayout()
		G.dealt_letters:snap_VT()
		G.dealt_letters:hard_set_cards()
	end
	if WORD_GAME_UI.TableControls then
		WORD_GAME_UI.TableControls.sync_position()
	end
	local stack_ui = bonus_stack_ui()
	if opts.keep_bonus_stack and stack_ui.sync_positions
		and not stack_ui.is_animating() then
		stack_ui.sync_positions()
	end
end

function M.show_bonus_flyovers(used_cards)
	local FloatUp = WORD_GAME_UI.FloatUpText
	if not FloatUp or not FloatUp.from_card then return end
	for _, card in ipairs(used_cards or {}) do
		local stack_ui = bonus_stack_ui()
		if stack_ui.is_bonus_card(card) then
			FloatUp.from_card(card, "+" .. tostring(stack_ui.BONUS_POINTS), {
				colour = G.C and G.C.GOLD or { 1, 0.85, 0.2, 1 },
			})
		end
	end
end

return M
