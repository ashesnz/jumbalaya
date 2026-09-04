--[[ word_game/model/match.lua - Match end / game-over transitions ]]

local state = require("word_game.model.state")

local M = {}

function M.end_run(opts)
	opts = opts or {}
	if type(delete_saved_run) == "function" then
		delete_saved_run()
	end
	local alpha = state.get()
	if alpha then
		alpha.match_over = true
		alpha.match_won = opts.won and true or false
	elseif G.GAME then
		G.GAME.alpha = G.GAME.alpha or {}
		G.GAME.alpha.match_over = true
		G.GAME.alpha.match_won = opts.won and true or false
	end
	if G.SETTINGS then
		G.SETTINGS.paused = true
	end
	state.record_current_jumble_if_best()
	G.STATE = G.STATES.GAME_OVER
	G.STATE_COMPLETE = false
	return true
end

return M
