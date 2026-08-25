--[[
	word_game/model/game/loop.lua - Game-over state handling.
]]

function Game:update_match_end(dt)
	if not G.STATE_COMPLETE then
		if type(delete_saved_run) == "function" then
			delete_saved_run()
		end

		play_sfx('negative', 0.5, 0.7)
		play_sfx('whoosh2', 0.9, 0.7)

		G.SETTINGS.paused = true
		local overlay_def = build_game_over()
		if WORD_GAME and WORD_GAME.EndMatch and WORD_GAME.EndMatch.overlay_definition then
			overlay_def = WORD_GAME.EndMatch.overlay_definition(false)
		end
		G.FUNCS.show_overlay{
			definition = overlay_def,
			config = {no_esc = true}
		}
		G.ROOM.jiggle = G.ROOM.jiggle + 3

		G.STATE_COMPLETE = true
	end
end
