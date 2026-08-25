--[[ word_game/config/economy.lua - Token income and trade pricing ]]

local M = {
	STARTING_CHIPS = 4,
	STARTING_TOKENS = 0,
	HAND_CLEAR_CHIPS = 4,
	UNUSED_PLAY_CHIPS = 2,
	TRADE_IN = 3,
	TRADE_ADD_COST = 10,
	TRADE_REMOVE_COST = 20,
	TRADE_MODIFIER_COST = 30,
}

function M.hand_payout(unused_plays)
	return M.HAND_CLEAR_CHIPS + (unused_plays or 0) * M.UNUSED_PLAY_CHIPS
end

return M
