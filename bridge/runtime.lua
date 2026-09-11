--[[
	bridge/runtime.lua - Phase 7/9 runtime service accessors (store, engine, game shell).
]]

local M = {}

local _game = nil

local function word_game()
	return package.loaded["word_game"]
end

--- Register the live Game instance (called from Game:construct).
function M.bind_game(game)
	_game = game
end

--- Live Game instance; falls back to global G during the Phase 9 strangler.
function M.game()
	if _game then
		return _game
	end
	return _G.G
end

function M.store()
	local wg = word_game()
	if wg and wg.store then
		return wg.store()
	end
	return nil
end

function M.engine()
	local wg = word_game()
	if wg and wg.engine then
		return wg.engine()
	end
	return nil
end

function M.state()
	local game = M.game()
	return game and game.STATE
end

function M.stage()
	local game = M.game()
	return game and game.STAGE
end

function M.settings()
	local game = M.game()
	return game and game.SETTINGS
end

return M
