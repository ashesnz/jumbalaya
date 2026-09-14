--[[ word_game/ui/play_effects/hand_clear/celebrate.lua - Hand/boss clear celebration FX ]]

local GameRT = require("word_game.ui.util.game_runtime")
local facade = require("word_game.ui.facade")

local feedback = facade.feedback()

local M = {}

local function runtime()
	return GameRT.game()
end

function M.play_hand_clear()
	local major = (runtime().pattern_row and runtime().pattern_row.area)
		or runtime().PLAY_ATTACH
		or runtime().ROOM_ATTACH
	if WORD_GAME_UI.Confetti then
		WORD_GAME_UI.Confetti.burst()
	end
	feedback.show("Hand Cleared", runtime().C.GOLD, 1.8, 0.15)
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
	feedback.show("Boss Defeated!", runtime().C.GOLD, 1.8, 0.15)
	play_sfx("applause", 1, 0.9)
	play_sfx("timpani", 0.92, 0.9)
end

return M
