--[[ word_game/model/run/input_lock.lua - Shared gameplay input gates ]]

local BonusStack = require("word_game.model.jumble.bonus_stack")
local Busy = require("word_game.model.run.busy")

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
	if BonusStack.is_animating() then
		return true
	end
	if Busy.on("play_hold_redraw_busy")
		or Busy.on("trade_ui_busy")
		or Busy.on("token_reward_busy")
		or Busy.on("card_fly_off_busy") then
		return true
	end
	return false
end

return M
