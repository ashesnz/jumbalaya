--[[ packages/jumbalaya_core/store/reducers/run_state.lua - Run-state reducers (no G) ]]

local immutable = require("jumbalaya_core.store.immutable")
local core_run_state = require("jumbalaya_core.store.run_state")

local M = {}

function M.RUN_STATE_INIT(state)
	state.run_state = core_run_state.new()
	return state
end

function M.RUN_STATE_ADD_TOKENS(state, action)
	local rs = immutable.copy_run_state(state.run_state) or core_run_state.new()
	core_run_state.add_tokens(rs, action.amount)
	state.run_state = rs
	return state
end

function M.RUN_STATE_SPEND_TOKENS(state, action)
	local rs = immutable.copy_run_state(state.run_state) or core_run_state.new()
	core_run_state.spend_tokens(rs, action.amount)
	state.run_state = rs
	return state
end

function M.RUN_STATE_ADD_PERK(state, action)
	if not action.id then return state end
	local rs = immutable.copy_run_state(state.run_state) or core_run_state.new()
	rs.perks = rs.perks or {}
	local slots = rs.perk_slots or 12
	if #rs.perks >= slots then return state end
	rs.perks[#rs.perks + 1] = action.id
	state.run_state = rs
	return state
end

function M.RUN_STATE_MARK_TRADE_USED(state)
	if not state.run_state then return state end
	local rs = immutable.copy_run_state(state.run_state)
	rs.trade_used_this_hand = true
	state.run_state = rs
	return state
end

function M.RUN_MATCH_END(state, action)
	if not state.run_state then return state end
	local rs = immutable.copy_run_state(state.run_state)
	rs.match_over = true
	rs.match_won = action.won and true or false
	state.run_state = rs
	return state
end

return M
