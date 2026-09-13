--[[
	word_game/model/jumble_play/jumble.lua - play_jumble_word entry, end_jumble_hand_model, deal_after_jumble_timeout

	Core: none
	Store: game_access.dispatch(END_JUMBLE_HAND)
	Presentation: none
]]

return function(M)
local Jumble = require("word_game.model.jumble")
local round = require("word_game.model.round")
local opening_deal = require("word_game.model.jumble_play.opening_deal")
local rules = require("word_game.model.jumble_play.jumble_rules")
local game_access = require("word_game.model.game_access")

function M.play_jumble_word(opts)
	opts = opts or {}
	local jumble = Jumble
	local j = jumble and jumble.state()
	return rules.evaluate_play(jumble, j)
end

function M.end_jumble_hand_model()
	local wr = game_access.word_round()
	if not wr or wr.mode ~= "jumble" then return nil end
	local score = wr.jumble and wr.jumble.total_score or 0
	game_access.dispatch({ type = "END_JUMBLE_HAND" })
	round.advance_hand()
	return score
end

function M.deal_after_jumble_timeout()
	opening_deal.deal()
end

end
