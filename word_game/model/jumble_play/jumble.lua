--[[ word_game/model/jumble_play/jumble.lua - Jumble play evaluation (no UI) ]]

return function(M)
local round = require("word_game.model.round")
local rules = require("word_game.model.jumble_play.jumble_rules")
local feedback = require("word_game.model.feedback")

function M.play_jumble_word(opts)
	opts = opts or {}
	local jumble = WORD_GAME and WORD_GAME.Jumble
	local j = jumble and jumble.state()
	return rules.evaluate_play(jumble, j)
end

function M.jumble_next(opts)
	opts = opts or {}
	require("word_game.ui.play_effects").present_jumble_next(
		WORD_GAME and WORD_GAME.Jumble,
		G.GAME and G.GAME.word_round,
		opts
	)
end

function M.end_jumble_hand()
	local wr = G.GAME.word_round
	if not wr or wr.mode ~= "jumble" then return end
	local j = wr.jumble
	local score = j and j.total_score or 0
	wr.mode = nil
	wr.jumble = nil
	G.GAME.word_score_animating = false

	feedback.show("Time!  " .. score .. " points", G.C.GOLD, 2.2, 0.35)
	play_sfx("timpani", 0.9, 0.85)

	if WORD_GAME and WORD_GAME.ScoreBanner then
		local hud = WORD_GAME.ScoreBanner.state()
		hud.to_go_label = "TO CLEAR"
	end

	round.advance_hand()
	require("word_game.model.jumble_play.opening_deal").deal()
end

end
