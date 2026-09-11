--[[
	word_game/ui/play_effects/resolution.lua - Apply play effects after model evaluation.

	Model (`Play.play_jumble_word`) returns an evaluation result; this module runs
	presentation and follow-up actions (banners, card fly, hand clear).
]]

local facade = require("word_game.ui.facade")
local effects = require("word_game.ui.play_effects")
local Presentation = require("word_game.model.presentation")
local game_access = require("word_game.model.game_access")

local RunMode = facade.run_mode()

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

	Presentation.emit("PLAY_RESOLVED", result)
	local runtime = require("app.runtime")
	local engine = runtime.engine()
	if engine and WORD_GAME_UI then
		local fx_subscribers = require("word_game.ui.fx_subscribers")
		fx_subscribers.install(engine, WORD_GAME_UI)
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
			effects.present_jumble_next(WORD_GAME and WORD_GAME.Jumble, game_access.word_round(), opts)
		end
		return result
	end

	local wr = game_access.word_round()
	effects.present_word_play_after_cards(
		WORD_GAME and WORD_GAME.Jumble,
		wr and wr.jumble,
		result,
		play_module.on_hand_cleared,
		opts.on_complete
	)
	return result
end

return M
