--[[ word_game/model/game_access.lua - Read/write game snapshot via store (Phase 8) ]]

local store_sync = require("bridge.store_sync")
local runtime = require("bridge.runtime")

local M = {}

local function store()
	return runtime.store()
end

function M.get()
	local s = store()
	if s then
		return s:get()
	end
	return store_sync.legacy_mirror_get()
end

function M.word_round()
	local game = M.get()
	return game and game.word_round
end

function M.dispatch(action)
	local game = M.get()
	if not game or not action then return game end
	local s = store()
	if s then
		return store_sync.dispatch(s, action)
	end
	local reducers = require("jumbalaya_core.store.reducers.init")
	reducers.reduce(game, action)
	return game
end

function M.patch(fields)
	local s = store()
	if s and fields then
		return store_sync.dispatch(s, { type = "GAME_PATCH", patch = fields })
	end
	return store_sync.legacy_mirror_patch(fields)
end

function M.mutate(fn)
	local game = M.get()
	if not game or not fn then return game end
	fn(game)
	return game
end

return M
