--[[ word_game/ui/sidebar/hand_progress.lua - Stage label roll hook for hand transitions ]]

local StageLabel = require("word_game.ui.stage_label")

local M = {}

function M.roll_plays()
end

function M.roll_to_next_hand()
	if WORD_GAME and WORD_GAME.StageLabel and WORD_GAME.StageLabel.roll_to_next_hand then
		WORD_GAME.StageLabel.roll_to_next_hand()
	elseif StageLabel.roll_to_next_hand then
		StageLabel.roll_to_next_hand()
	end
end

function M.reset()
	if WORD_GAME and WORD_GAME.StageLabel and WORD_GAME.StageLabel.reset then
		WORD_GAME.StageLabel.reset()
	elseif StageLabel.reset then
		StageLabel.reset()
	end
end

return M
