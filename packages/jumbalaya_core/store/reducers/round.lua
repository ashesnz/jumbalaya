--[[ packages/jumbalaya_core/store/reducers/round.lua - Round progression reducers (no G) ]]

local core_round = require("jumbalaya_core.round")

local M = {}

function M.ROUND_INIT_RUN(state)
	state.word_round = core_round.new_word_round(1, 1)
	for key, value in pairs(core_round.run_reset_fields()) do
		state[key] = value
	end
	return state
end

function M.ROUND_START_HAND(state, action)
	state.word_round = core_round.start_hand_coords(action.set, action.hand_index)
	if action.trade_reset and state.run_state then
		state.run_state.trade_used_this_hand = false
	end
	return state
end

function M.ROUND_RECORD_WORD(state, action)
	core_round.record_word_play(state.word_round, action.word)
	return state
end

function M.ROUND_SET_WORD_ROUND(state, action)
	state.word_round = action.word_round
	return state
end

function M.PLAY_WORD(state, action)
	if action.word and state.word_round then
		core_round.record_word_play(state.word_round, action.word)
	end
	return state
end

function M.SHUFFLE_HAND(state, action)
	return state
end

function M.RETURN_PLACEMENT_CARDS(state, action)
	return state
end

function M.JUMBLE_NEXT(state, action)
	return state
end

return M
