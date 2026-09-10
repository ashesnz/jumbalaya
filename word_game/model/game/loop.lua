--[[
	word_game/model/game/loop.lua - Game-over state handling.
]]

local Presentation = require("word_game.model.presentation")

function Game:update_match_end(dt)
	if not G.STATE_COMPLETE then
		if type(delete_saved_run) == "function" then
			delete_saved_run()
		end

		play_sfx('negative', 0.5, 0.7)
		play_sfx('whoosh2', 0.9, 0.7)

		G.SETTINGS.paused = true
		Presentation.emit("match_ended", false)
		G.ROOM.jiggle = G.ROOM.jiggle + 3

		G.STATE_COMPLETE = true
	end
end
