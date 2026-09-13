--[[ packages/jumbalaya_core/store/reducers/round.lua - Round progression reducers (no G) ]]

local immutable = require("jumbalaya_core.store.immutable")
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
		local rs = immutable.copy_run_state(state.run_state)
		rs.trade_used_this_hand = false
		state.run_state = rs
	end
	return state
end

function M.ROUND_RECORD_WORD(state, action)
	local wr = immutable.copy_word_round(state.word_round)
	core_round.record_word_play(wr, action.word)
	state.word_round = wr
	return state
end

function M.ROUND_SET_WORD_ROUND(state, action)
	state.word_round = action.word_round
	return state
end

function M.PLAY_WORD(state, action)
	local word = action.word or state.placement_word
	if word and word ~= "" and state.word_round then
		local wr = immutable.copy_word_round(state.word_round)
		core_round.record_word_play(wr, word)
		state.word_round = wr
	end
	state.last_gameplay_action = "PLAY_WORD"
	return state
end

function M.SHUFFLE_HAND(state, action)
	state.last_gameplay_action = "SHUFFLE_HAND"
	state.shuffle_hand_count = (state.shuffle_hand_count or 0) + 1
	return state
end

function M.RETURN_PLACEMENT_CARDS(state, action)
	state.last_gameplay_action = "RETURN_PLACEMENT_CARDS"
	return state
end

function M.JUMBLE_NEXT(state, action)
	state.last_gameplay_action = "JUMBLE_NEXT"
	return state
end

function M.CLASSIC_STAGE_NEXT(state, action)
	state.last_gameplay_action = "CLASSIC_STAGE_NEXT"
	return state
end

function M.END_JUMBLE_HAND(state)
	local wr = state.word_round
	if not wr or wr.mode ~= "jumble" then return state end
	wr = immutable.copy_word_round(wr)
	wr.mode = nil
	wr.jumble = nil
	state.word_round = wr
	state.word_score_animating = false
	return state
end

return M
