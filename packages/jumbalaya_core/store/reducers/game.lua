--[[ packages/jumbalaya_core/store/reducers/game.lua - Top-level game snapshot patches (no G) ]]

local immutable = require("jumbalaya_core.store.immutable")

local M = {}

function M.GAME_PATCH(state, action)
	for key, value in pairs(action.patch or {}) do
		state[key] = value
	end
	return state
end

function M.SET_PLACEMENT_PREVIEW(state, action)
	state.placement_word = action.word or ""
	state.placement_word_valid = action.valid == true
	return state
end

function M.SET_BUSY_FLAG(state, action)
	if action.name then
		state[action.name] = action.on and true or nil
	end
	return state
end

function M.CLEAR_BUSY_FLAGS(state, action)
	for _, name in ipairs(action.names or {}) do
		state[name] = nil
	end
	return state
end

function M.SET_VOUCHER_DISCARDS_USED(state, action)
	local count = math.max(0, action.count or 0)
	state.voucher_discards_used = count
	state.discard_bin_count = count
	return state
end

function M.SET_SELECTED_PERK(state, action)
	state.selected_perk = action.perk
	return state
end

function M.RECORD_CARD_DISCARDED(state)
	local scores = state.round_scores or {}
	local discarded = scores.cards_discarded or { amt = 0 }
	state.round_scores = immutable.shallow_copy(scores)
	state.round_scores.cards_discarded = { amt = (discarded.amt or 0) + 1 }
	return state
end

function M.TRADE_PICK(state, action)
	state.last_trade_action = "TRADE_PICK"
	return state
end

function M.TRADE_SKIP(state, action)
	state.last_trade_action = "TRADE_SKIP"
	return state
end

function M.TRADE_SKIP_ADD(state, action)
	state.last_trade_action = "TRADE_SKIP_ADD"
	return state
end

function M.TRADE_SKIP_REMOVE(state, action)
	state.last_trade_action = "TRADE_SKIP_REMOVE"
	return state
end

return M
