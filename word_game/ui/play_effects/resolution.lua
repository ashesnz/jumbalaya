--[[
	word_game/ui/play_resolution.lua - Apply play effects after model evaluation.

	Model (`Play.play_word`) returns an evaluation result; this module runs
	presentation and follow-up actions (banners, card fly, hand clear).
]]

local RunMode = require("word_game.model.run_mode")
local effects = require("word_game.ui.play_effects")

local M = {}

local function ends_hand_on_target(cleared)
	return cleared and RunMode.ends_hand_on_target()
end

function M.resolve(play_module, opts)
	opts = opts or {}
	local result = play_module.play_jumble_word(opts)
	if not result then return nil end

	if result.kind == "invalid" then
		effects.show_validation_error(result.err)
		return result
	end

	effects.roll_jumble_banners(result)
	local boss_trigger = effects.triggers_boss_word(result)
	effects.capture_token_timer_if_cleared(ends_hand_on_target(result.cleared), { skip_focus = boss_trigger })

	if result.kind == "bank_puzzle" then
		if ends_hand_on_target(result.cleared) then
			effects.set_word_score_animating(true)
			effects.add_points(result.puzzle_total)
			play_module.on_hand_cleared()
		else
			effects.show_puzzle_bank_feedback(result.puzzle_total)
			opts.instant = opts.instant ~= false
			effects.present_jumble_next(WORD_GAME and WORD_GAME.Jumble, G.GAME.word_round, opts)
		end
		return result
	end

	effects.present_word_play_after_cards(
		WORD_GAME and WORD_GAME.Jumble,
		G.GAME and G.GAME.word_round and G.GAME.word_round.jumble,
		result,
		play_module.on_hand_cleared,
		opts.on_complete
	)
	return result
end

return M
