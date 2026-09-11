--[[ packages/jumbalaya_core/store/reducers/game.lua - Top-level game snapshot patches (no G) ]]

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

return M
