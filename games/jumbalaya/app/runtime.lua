--[[
	app/runtime.lua - Runtime service accessors (store, engine, game shell).
]]

local shell = require("jumbalaya-engine.shell")

local M = {}

local function word_game()
	return package.loaded["word_game"]
end

--- Register the live Game instance (called from Game:construct).
function M.bind_game(game)
	shell.bind_game(game)
end

--- Live Game instance (bound from Game:construct).
function M.game()
	return shell.game()
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

--- Bound run snapshot accessor (wired in app/bootstrap/shell_bind.lua).
function M.game_access()
	return shell.game_access()
end

return M
