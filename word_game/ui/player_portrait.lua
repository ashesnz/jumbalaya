--[[ word_game/ui/player_portrait.lua - Timeline HUD draw passthrough. ]]

local M = {}

function M.draw()
	if not G.GAME or not G.ROOM then return end
	if G.STATE ~= G.STATES.TABLE_BOARD then return end
	if WORD_GAME and WORD_GAME.TimelineTimer and WORD_GAME.TimelineTimer.draw then
		WORD_GAME.TimelineTimer.draw()
	end
end

return M
