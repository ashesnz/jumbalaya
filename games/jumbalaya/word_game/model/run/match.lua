--[[ word_game/model/run/match.lua - Match end / game-over transitions ]]

local live_game = require("word_game.model.live_game")

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
	if live_game().SETTINGS then
		live_game().SETTINGS.paused = true
	end
	state.record_current_jumble_if_best()
	live_game().STATE = live_game().STATES.GAME_OVER
	live_game().STATE_COMPLETE = false
	return true
end

return M
