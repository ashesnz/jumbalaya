--[[ word_game/model/input_lock.lua - Shared gameplay input gates ]]

local M = {}

function M.is_table_busy()
	if not G or not G.GAME then return false end
	local game = G.GAME
	if game.word_score_animating
		or game.hand_redraw_animating
		or game.hand_shuffle_animating
		or game.placement_recall_animating then
		return true
	end
	local jumble = game.word_round and game.word_round.jumble
	if jumble and jumble.boss_word_staging then
		return true
	end
	if WORD_GAME and WORD_GAME.PlayHoldRedraw and WORD_GAME.PlayHoldRedraw.is_animating() then
		return true
	end
	return false
end

return M
