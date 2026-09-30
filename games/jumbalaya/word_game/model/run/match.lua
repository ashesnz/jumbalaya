--[[
	word_game/model/run/match.lua - end_run: delete save, dispatch match end, pause, set GAME_OVER state

	Core: none
	Store: game_access.dispatch(RUN_MATCH_END)
	Presentation: match_ended
]]

local live_game = require("word_game.model.live_game")

local Presentation = require("word_game.model.presentation")
local state = require("word_game.model.run.state")
local game_access = require("word_game.model.game_access")

local M = {}

function M.end_run(opts)
	opts = opts or {}
	local won = opts.won and true or false
	if type(delete_saved_run) == "function" then
		delete_saved_run()
	end
	if game_access.get() then
		game_access.dispatch({ type = "RUN_MATCH_END", won = won })
	end
	if live_game().SETTINGS then
		live_game().SETTINGS.paused = true
	end
	state.record_current_jumble_if_best()
	live_game().STATE = live_game().STATES.GAME_OVER
	-- Overlay is opened from match_ended; skip Game:update_match_end's second emit.
	live_game().STATE_COMPLETE = true
	Presentation.emit("match_ended", won)
	return true
end

return M
