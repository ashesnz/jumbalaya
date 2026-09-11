--[[
	jumbalaya-engine/shell.lua - Bound Game shell + app callbacks (injected at boot; no app/ import).
]]

local M = {}

local _game = nil
local _app_events = nil
local _funcs = nil
local _action_dispatch = nil

function M.bind_game(game)
	_game = game
end

function M.game()
	return _game
end

function M.bind_app_events(module)
	_app_events = module
end

function M.emit_app_action(action)
	if _app_events and _app_events.emit then
		_app_events.emit(action)
	end
end

function M.bind_funcs(module)
	_funcs = module
end

function M.funcs()
	return _funcs
end

function M.get_func(name)
	if _funcs and _funcs.get then
		return _funcs.get(name)
	end
end

function M.dispatch_func(name, ...)
	if _funcs and _funcs.dispatch then
		return _funcs.dispatch(name, ...)
	end
end

function M.bind_action_dispatch(module)
	_action_dispatch = module
end

function M.dispatch_action(action)
	if _action_dispatch and _action_dispatch.dispatch then
		_action_dispatch.dispatch(action)
	end
end

function M.dispatch_action_func(name, extra)
	if _action_dispatch and _action_dispatch.dispatch_func then
		return _action_dispatch.dispatch_func(name, extra)
	end
	return false
end

return M
