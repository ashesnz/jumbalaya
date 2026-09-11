--[[ bridge/action_dispatch.lua - Phase 4 unified action dispatch via engine InputService ]]

local store_sync = require("bridge.store_sync")

local M = {}

local function engine_input()
	if G and G._engine and G._engine.input then
		return G._engine.input
	end
	return nil
end

function M.dispatch(action)
	if not action then return end
	local input = engine_input()
	if input then
		input:on_action(action)
		return
	end
	if G and G._store then
		store_sync.dispatch(G._store, action)
	end
end

function M.dispatch_func(name, extra)
	local input = engine_input()
	if input and input:dispatch_func(name, extra) then
		return true
	end
	local Engine = require("jumbalaya-engine")
	local template = Engine.InputService.ACTION_MAP[name]
	if not template then return false end
	local action = {}
	for key, value in pairs(template) do
		action[key] = value
	end
	if extra then
		for key, value in pairs(extra) do
			action[key] = value
		end
	end
	M.dispatch(action)
	return true
end

return M
