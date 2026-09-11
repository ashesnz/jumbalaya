--[[ app/bootstrap/store_boot.lua - Phase 2: instantiate store and bind WORD_GAME ]]

local store_sync = require("bridge.store_sync")

local M = {}

function M.install()
	if not G then return nil end
	G._store = store_sync.new()
	store_sync.sync_from_g(G._store)
	store_sync.sync_to_g(G._store)
	if WORD_GAME and WORD_GAME._bind_store then
		WORD_GAME._bind_store(G._store)
	end
	require("app.bootstrap.engine_services_boot").install()
	return G._store
end

return M
