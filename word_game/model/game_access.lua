--[[ word_game/model/game_access.lua - Read/write game snapshot via store (Phase 2) ]]

local store_sync = require("bridge.store_sync")

local M = {}

function M.get()
	if G and G._store then
		if G.GAME and G.GAME ~= G._store:get() then
			store_sync.adopt_current_g_game(G._store)
		end
		return G._store:get()
	end
	return G and G.GAME
end

function M.word_round()
	local game = M.get()
	return game and game.word_round
end

function M.dispatch(action)
	local game = M.get()
	if not game or not action then return game end
	if G and G._store then
		return store_sync.dispatch(G._store, action)
	end
	local reducers = require("jumbalaya_core.store.reducers.init")
	reducers.reduce(game, action)
	return game
end

function M.patch(fields)
	if G and G._store then
		return store_sync.dispatch(G._store, { type = "GAME_PATCH", patch = fields })
	end
	local game = G and G.GAME
	if game and fields then
		for key, value in pairs(fields) do
			game[key] = value
		end
	end
	return game
end

function M.mutate(fn)
	local game = M.get()
	if not game or not fn then return game end
	fn(game)
	if G and G._store then
		store_sync.sync_to_g(G._store)
	end
	return game
end

return M
