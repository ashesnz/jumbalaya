--[[ packages/jumbalaya_core/store/selectors/piles.lua - Pile selectors (no G) ]]

local M = {}

local function pile(state, name)
	return state and state.piles and state.piles[name] or {}
end

function M.hand_cards(state)
	return pile(state, "hand")
end

function M.draw_cards(state)
	return pile(state, "draw")
end

function M.pattern_cards(state)
	return pile(state, "pattern")
end

function M.discard_cards(state)
	return pile(state, "discard")
end

function M.bonus_cards(state)
	return pile(state, "bonus")
end

return M
