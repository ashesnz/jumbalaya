--[[ packages/jumbalaya_core/store/reducers/init.lua - Action reducer registry (no G) ]]

local round = require("jumbalaya_core.store.reducers.round")
local run_state = require("jumbalaya_core.store.reducers.run_state")
local game = require("jumbalaya_core.store.reducers.game")
local piles = require("jumbalaya_core.store.reducers.piles")

local M = {}

local handlers = {}

local function register(module)
	for key, fn in pairs(module) do
		if type(fn) == "function" and key:match("^[A-Z]") then
			handlers[key] = fn
		end
	end
end

register(round)
register(run_state)
register(game)
register(piles)

function M.reduce(state, action)
	if not action or not action.type then return state end
	local handler = handlers[action.type]
	if not handler then return state end
	return handler(state, action)
end

return M
