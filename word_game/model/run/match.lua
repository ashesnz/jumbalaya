--[[ word_game/model/run/match.lua - Match end / game-over transitions ]]

local state = require("word_game.model.run.state")
local game_access = require("word_game.model.game_access")

local M = {}

function M.end_run(opts)
	opts = opts or {}
	if type(delete_saved_run) == "function" then
		delete_saved_run()
	end
	if G and G._store and game_access.get() then
		game_access.dispatch({ type = "RUN_MATCH_END", won = opts.won })
	elseif G and G.GAME then
		state.migrate_legacy_field(G.GAME)
		G.GAME.run_state = G.GAME.run_state or {}
		G.GAME.run_state.match_over = true
		G.GAME.run_state.match_won = opts.won and true or false
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
