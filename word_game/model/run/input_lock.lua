--[[ word_game/model/run/input_lock.lua - Shared gameplay input gates ]]

local BonusStack = require("word_game.model.jumble.bonus_stack")

local M = {}

local function trade_ui_busy()
	if not WORD_GAME or not WORD_GAME.TradeUI then return false end
	local trade = WORD_GAME.TradeUI
	if trade.is_flying and trade.is_flying() then return true end
	if trade.is_transforming and trade.is_transforming() then return true end
	return false
end

local function token_reward_busy()
	if not WORD_GAME or not WORD_GAME.TokenReward then return false end
	local reward = WORD_GAME.TokenReward
	return reward.is_active and reward.is_active()
end

local function card_fly_off_busy()
	if not WORD_GAME or not WORD_GAME.CardFlyOff then return false end
	local fly = WORD_GAME.CardFlyOff
	return fly.is_active and fly.is_active()
end

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
	if WORD_GAME and WORD_GAME.PlayHoldRedraw and WORD_GAME.PlayHoldRedraw.is_animating() then
		return true
	end
	if trade_ui_busy() then return true end
	if token_reward_busy() then return true end
	if card_fly_off_busy() then return true end
	return false
end

return M
