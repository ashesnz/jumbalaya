--[[ word_game/model/play/jumble.lua ]]

return function(M)
local round = require("word_game.model.round")
local rules = require("word_game.model.play.jumble_rules")
local effects = require("word_game.ui.play_effects")
local word_feedback = require("word_game.ui.word_feedback")

function M.play_jumble_word(opts)
	opts = opts or {}
	local jumble = WORD_GAME and WORD_GAME.Jumble
	local j = jumble and jumble.state()
	local result = rules.evaluate_play(jumble, j)
	if not result then return end

	if result.kind == "invalid" then
		effects.show_validation_error(result.err)
		return
	end

	effects.roll_jumble_banners(result)
	local boss_trigger = effects.triggers_boss_word(result)
	effects.capture_token_timer_if_cleared(result.new_rem <= 0, { skip_focus = boss_trigger })

	if result.kind == "bank_puzzle" then
		effects.sidebar_add_puzzle_play(result.puzzle_label, result.puzzle_total)
		if result.cleared then
			effects.set_word_score_animating(true)
			effects.add_points(result.puzzle_total)
			M.on_hand_cleared()
		else
			effects.show_puzzle_bank_feedback(result.puzzle_total)
			opts.instant = opts.instant ~= false
			M.jumble_next(opts)
		end
		return
	end

	effects.present_word_play_after_cards(jumble, j, result, M.on_hand_cleared, opts.on_complete)
end

function M.jumble_next(opts)
	opts = opts or {}
	local jumble = WORD_GAME and WORD_GAME.Jumble
	if not rules.can_jumble_next(jumble) then return end
	local wr = G.GAME.word_round
	effects.present_jumble_next(jumble, wr, opts)
end

function M.end_jumble_hand()
	local wr = G.GAME.word_round
	if not wr or wr.mode ~= "jumble" then return end
	local j = wr.jumble
	local score = j and j.total_score or 0
	wr.mode = nil
	wr.jumble = nil
	G.GAME.word_score_animating = false

	word_feedback.show("Time!  " .. score .. " points", G.C.GOLD, 2.2, 0.35)
	play_sfx("timpani", 0.9, 0.85)

	if WORD_GAME and WORD_GAME.ScoreBanner then
		local hud = WORD_GAME.ScoreBanner.state()
		hud.to_go_label = "TO CLEAR"
	end

	round.advance_hand()
	require("word_game.model.play.opening_deal").deal()
	effects.present_end_jumble_sidebar()
end

end
