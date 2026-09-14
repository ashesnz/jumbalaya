--[[ word_game/ui/trade/session_state.lua - Marketplace offer + per-visit session ]]

local M = {}

local offer
local session
local standalone = false

function M.offer()
	return offer
end

function M.session()
	return session
end

function M.is_standalone()
	return standalone
end

function M.set_standalone(value)
	standalone = value == true
end

function M.reset(rolled)
	offer = rolled
	session = {
		add_done = false,
		remove_done = true,
		added = nil,
		removed = nil,
		add_cost_bonus = 0,
		modified = {},
		removing = {},
	}
	if rolled and rolled.showdown and not rolled.remove then
		session.remove_done = true
	end
end

function M.session_complete()
	return session and session.add_done and session.remove_done
end

function M.broke_after_last_action()
	return session and session.broke_after_action or false
end

function M.teardown()
	offer = nil
	session = nil
	standalone = false
end

return M
