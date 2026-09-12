--[[
	word_game/model/game/loop.lua - Game:update_match_end — loss transition, pause, saved-run cleanup

	Core: none
	Store: none
	Presentation: match_ended
]]

local live_game = require("word_game.model.live_game")

local Presentation = require("word_game.model.presentation")

function Game:update_match_end(dt)
	if not self.STATE_COMPLETE then
		if type(delete_saved_run) == "function" then
			delete_saved_run()
		end

		play_sfx('negative', 0.5, 0.7)
		play_sfx('whoosh2', 0.9, 0.7)

		self.SETTINGS.paused = true
		Presentation.emit("match_ended", false)
		self.ROOM.jiggle = self.ROOM.jiggle + 3

		self.STATE_COMPLETE = true
	end
end
