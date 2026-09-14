--[[ word_game/ui/play_effects/hand_clear/celebrate.lua - Hand/boss clear celebration FX ]]

local game = require("word_game.ui.util.game_runtime").game
local facade = require("word_game.ui.facade")

local feedback = facade.feedback()

local M = {}


function M.play_hand_clear()
	local major = (game().pattern_row and game().pattern_row.area)
		or game().PLAY_ATTACH
		or game().ROOM_ATTACH
	if WORD_GAME_UI.Confetti then
		WORD_GAME_UI.Confetti.burst()
	end
	feedback.show("Hand Cleared", game().C.GOLD, 1.8, 0.15)
	play_sfx("applause", 1, 0.9)
	play_sfx("timpani", 0.92, 0.9)
	play_sfx("card_tick", 0.6, 0.5)
	if major and major.pulse then
		major:pulse(0.35, 0.2)
	end
end

function M.play_boss_clear()
	if WORD_GAME_UI.Confetti then
		WORD_GAME_UI.Confetti.burst()
	end
	feedback.show("Boss Defeated!", game().C.GOLD, 1.8, 0.15)
	play_sfx("applause", 1, 0.9)
	play_sfx("timpani", 0.92, 0.9)
end

return M
