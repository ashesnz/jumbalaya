--[[ packages/jumbalaya_core/store/reducers/run_state.lua - Run-state reducers (no G) ]]

local core_run_state = require("jumbalaya_core.store.run_state")

local M = {}

function M.RUN_STATE_INIT(state)
	state.run_state = core_run_state.new()
	return state
end

function M.RUN_STATE_ADD_TOKENS(state, action)
	core_run_state.add_tokens(state.run_state, action.amount)
	return state
end

function M.RUN_STATE_SPEND_TOKENS(state, action)
	core_run_state.spend_tokens(state.run_state, action.amount)
	return state
end

function M.RUN_STATE_ADD_PERK(state, action)
	local rs = state.run_state
	if not rs or not action.id then return state end
	rs.perks = rs.perks or {}
	local slots = rs.perk_slots or 12
	if #rs.perks >= slots then return state end
	rs.perks[#rs.perks + 1] = action.id
	return state
end

function M.RUN_STATE_MARK_TRADE_USED(state)
	local rs = state.run_state
	if rs then
		rs.trade_used_this_hand = true
	end
	return state
end

function M.RUN_MATCH_END(state, action)
	local rs = state.run_state
	if rs then
		rs.match_over = true
		rs.match_won = action.won and true or false
	end
	return state
end

return M
