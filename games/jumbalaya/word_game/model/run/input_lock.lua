--[[
	word_game/model/run/input_lock.lua - Blocks table input during score/shuffle/boss/bonus/busy animations

	Core: none
	Store: game_access.get animation/busy flags
	Presentation: none
]]

local BonusStack = require("word_game.model.jumble.bonus_stack")
local Busy = require("word_game.model.run.busy")
local game_access = require("word_game.model.game_access")

local M = {}

function M.is_table_busy()
	local game = game_access.get()
	if not game then return false end
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
