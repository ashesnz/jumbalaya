--[[ word_game/model/jumble_play/jumble.lua - Jumble play evaluation (no UI imports) ]]

return function(M)
local round = require("word_game.model.round")
local opening_deal = require("word_game.model.jumble_play.opening_deal")
local rules = require("word_game.model.jumble_play.jumble_rules")
local store_sync = require("bridge.store_sync")
local runtime = require("bridge.runtime")
local game_access = require("word_game.model.game_access")

function M.play_jumble_word(opts)
	opts = opts or {}
	local jumble = WORD_GAME and WORD_GAME.Jumble
	local j = jumble and jumble.state()
	local result = rules.evaluate_play(jumble, j)
	local store = runtime.store()
	if result and store then
		store_sync.sync_to_g(store)
	end
	return result
end

function M.end_jumble_hand_model()
	local wr = game_access.word_round()
	if not wr or wr.mode ~= "jumble" then return nil end
	local j = wr.jumble
	local score = j and j.total_score or 0
	wr.mode = nil
	wr.jumble = nil
	game_access.patch({ word_score_animating = false })
	round.advance_hand()
	local store = runtime.store()
	if store then
		store_sync.sync_to_g(store)
	end
	return score
end

function M.deal_after_jumble_timeout()
	opening_deal.deal()
end

end
