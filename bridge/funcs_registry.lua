--[[
	bridge/funcs_registry.lua - Register G.FUNCS handlers and re-bind on new Game instances.
]]

local BridgeRuntime = require("bridge.runtime")

local M = {}
local pending = {}

function M.register(name, fn)
	pending[name] = fn
	local game = BridgeRuntime.game()
	if game and game.FUNCS then
		game.FUNCS[name] = fn
	end
end

function M.install(game)
	if not game then return end
	game.FUNCS = game.FUNCS or {}
	for name, fn in pairs(pending) do
		game.FUNCS[name] = fn
	end
end

return M
