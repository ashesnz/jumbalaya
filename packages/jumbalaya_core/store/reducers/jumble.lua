--[[ packages/jumbalaya_core/store/reducers/jumble.lua - Jumble word_round reducers (no G) ]]

local immutable = require("jumbalaya_core.store.immutable")
local core_hand = require("jumbalaya_core.jumble.hand")
local modifier_effects = require("jumbalaya_core.rules.letter_modifier_effects")

local M = {}

local function replace_word_round(state, wr)
	state.word_round = wr
	return state
end

--- Apply a resolved puzzle (pure core). Glue may pass a pre-built word_round copy
--- (after presentation hooks) via action.word_round instead of action.puzzle.
function M.JUMBLE_APPLY_PUZZLE(state, action)
	if not state.word_round then return state end
	if action.word_round then
		return replace_word_round(state, immutable.copy_word_round(action.word_round))
	end
	if not action.puzzle then return state end
	local wr = immutable.copy_word_round(state.word_round)
	core_hand.apply_puzzle(wr, action.puzzle, nil)
	return replace_word_round(state, wr)
end

function M.JUMBLE_LOAD_PUZZLE(state, action)
	if not state.word_round or not action.index then return state end
	local wr = immutable.copy_word_round(state.word_round)
	core_hand.load_puzzle(wr, action.index, action.puzzle_list or {})
	return replace_word_round(state, wr)
end

function M.JUMBLE_START_HAND(state, action)
	if not state.word_round then return state end
	local wr = immutable.copy_word_round(state.word_round)
	modifier_effects.reset_stage_state(wr)
	core_hand.start_hand(wr, { puzzle_list = action.puzzle_list or {} })
	return replace_word_round(state, wr)
end

function M.JUMBLE_RECORD_WORD(state, action)
	if not state.word_round or not state.word_round.jumble or not action.jumble then return state end
	local wr = immutable.copy_word_round(state.word_round)
	local j = wr.jumble
	local patch = action.jumble
	if patch.puzzle_words then
		j.puzzle_words = immutable.shallow_copy(patch.puzzle_words)
	end
	if patch.puzzle_points ~= nil then
		j.puzzle_points = patch.puzzle_points
	end
	if patch.puzzle_multi ~= nil then
		j.puzzle_multi = patch.puzzle_multi
	end
	if patch.solved ~= nil then
		j.solved = patch.solved
	end
	if patch.next_word_multi_bonus ~= nil then
		j.next_word_multi_bonus = patch.next_word_multi_bonus
	end
	return replace_word_round(state, wr)
end

function M.JUMBLE_ADVANCE_PUZZLE(state, action)
	if not state.word_round or not state.word_round.jumble then return state end
	local wr = immutable.copy_word_round(state.word_round)
	core_hand.advance_puzzle(wr, action.puzzle_list or {})
	return replace_word_round(state, wr)
end

function M.JUMBLE_PREPARE_BOSS_WORD(state, action)
	if not state.word_round then return state end
	local wr = immutable.copy_word_round(state.word_round)
	if not core_hand.prepare_boss_word(wr, action.boss) then
		return state
	end
	return replace_word_round(state, wr)
end

function M.JUMBLE_REVEAL_BOSS_PUZZLE(state, action)
	if not state.word_round then return state end
	if action.word_round then
		return replace_word_round(state, immutable.copy_word_round(action.word_round))
	end
	local wr = immutable.copy_word_round(state.word_round)
	if not core_hand.reveal_boss_puzzle(wr, nil) then
		return state
	end
	return replace_word_round(state, wr)
end

function M.JUMBLE_SET_BOSS_STAGING(state)
	if not state.word_round or not state.word_round.jumble then return state end
	local wr = immutable.copy_word_round(state.word_round)
	wr.jumble.boss_word_staging = true
	return replace_word_round(state, wr)
end

return M
