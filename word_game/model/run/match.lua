--[[ word_game/model/run/match.lua - Match end / game-over transitions ]]

local state = require("word_game.model.run.state")
local game_access = require("word_game.model.game_access")

local M = {}

function M.end_run(opts)
	opts = opts or {}
	if type(delete_saved_run) == "function" then
		delete_saved_run()
	end
	if game_access.get() then
		game_access.dispatch({ type = "RUN_MATCH_END", won = opts.won })
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
