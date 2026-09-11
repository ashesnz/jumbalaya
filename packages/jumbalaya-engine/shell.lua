--[[
	jumbalaya-engine/shell.lua - Bound Game shell accessor (injected at boot; no app/ import).
]]

local M = {}

local _game = nil
local _app_events = nil

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

return M
