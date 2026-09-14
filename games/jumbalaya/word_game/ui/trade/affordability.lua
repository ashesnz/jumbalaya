--[[ word_game/ui/trade/affordability.lua - Token costs and action eligibility ]]

local facade = require("word_game.ui.facade")

local M = {}

M.ADD_COST_STEP = 10

local function trade_model()
	return facade.trade()
end

local function run_state()
	return facade.run_state()
end

local function deck_model()
	return facade.deck()
end

function M.session_add_cost(session_state)
	return trade_model().ACTION_COSTS.add + (session_state and session_state.add_cost_bonus or 0)
end

function M.can_afford_action(action, session_state)
	local balance = run_state().tokens()
	if action == "add" then
		return balance >= M.session_add_cost(session_state)
	end
	if action == "remove" then
		return balance >= trade_model().ACTION_COSTS.remove
	end
	if action == "modifier" then
		return balance >= trade_model().ACTION_COSTS.modifier
	end
	return false
end

function M.is_action_disabled(action, item, session_state)
	if action == "add" then
		return not M.can_afford_action("add", session_state)
	end
	if action == "remove" then
		return not trade_model().item_in_deck(item) or not M.can_afford_action("remove", session_state)
	end
	if action == "modifier" then
		local already_modified = item.card and deck_model().is_modified(item.card)
		local modified_this_session = session_state
			and session_state.modified
			and session_state.modified[item]
		return not trade_model().item_in_deck(item)
			or modified_this_session
			or already_modified
			or not M.can_afford_action("modifier", session_state)
	end
	return true
end

-- True when the token balance is lower than the cheapest action still
-- available on the board (Add is always offered; Remove/Modify only count
-- while an offered card is in the deck and eligible).
function M.cannot_afford_anything(offer, session, opts)
	if not session or not offer then return false end
	local balance = run_state().tokens()
	local letters = (offer.add or offer).letters or {}
	local any_in_deck = false
	local modify_available = false
	for _, item in ipairs(letters) do
		if trade_model().item_in_deck(item) then
			any_in_deck = true
			if not session.modified[item]
				and not (item.card and deck_model().is_modified(item.card)) then
				modify_available = true
			end
		end
	end
	local min_cost = M.session_add_cost(session)
	if opts and opts.after_add_purchase then
		min_cost = min_cost + M.ADD_COST_STEP
	end
	if any_in_deck then
		min_cost = math.min(min_cost, trade_model().ACTION_COSTS.remove)
		if modify_available then
			min_cost = math.min(min_cost, trade_model().ACTION_COSTS.modifier)
		end
	end
	return balance < min_cost
end

return M
