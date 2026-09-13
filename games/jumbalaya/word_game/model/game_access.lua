--[[
	word_game/model/game_access.lua - Read/write run snapshot via shell-bound store.

	Core: jumbalaya_core.store reducers (via word_game.model.store_ops)
	Store: get / patch / dispatch / mutate on GameRunState (types/store.lua)
	Presentation: none — callers emit after store writes
]]

local store_ops = require("word_game.model.store_ops")

local M = {}

function M.get()
	return store_ops.get()
end

function M.word_round()
	local game = M.get()
	return game and game.word_round
end

function M.dispatch(action)
	return store_ops.dispatch(nil, action)
end

function M.patch(fields)
	return store_ops.patch(nil, fields)
end

function M.mutate(fn)
	return store_ops.mutate(fn)
end

return M
