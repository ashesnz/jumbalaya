--[[
	bridge/store_sync.lua - Phase 0–2 store ↔ G.GAME compatibility shim.

	Contract (engine migration Phase 0–2):
	- The store owns run snapshot state during migration.
	- G.GAME is a mirror for legacy readers until Phase 7 removes G.
	- New code should use store APIs; do not write G.GAME directly once a
	  module has been migrated to dispatch through the store.

	Delegates to jumbalaya_core.Store; mirrors onto G.GAME for legacy readers.
]]

local CoreStore = require("jumbalaya_core.store")
local default_state = require("jumbalaya_core.store.default_state")

local M = {}

---@return table store GameStore instance with G sync hooks
function M.new(initial)
	local store = CoreStore.new(initial or default_state.new())
	return store
end

---@param store table
---@return table
function M.get_state(store)
	return store:get()
end

---@param store table
---@param state table
function M.replace(store, state)
	store:replace(state)
	M.sync_to_g(store)
end

---@param store table
---@param patch table
function M.patch(store, patch)
	store:patch(patch)
	M.sync_to_g(store)
end

--- Mirror store state onto G.GAME for legacy modules.
---@param store GameStore
function M.sync_to_g(store)
	if _G.G then
		_G.G.GAME = store:get()
	end
end

--- Bootstrap helper: adopt the current G.GAME table as store state.
---@param store table
function M.sync_from_g(store)
	if _G.G and _G.G.GAME then
		store:replace(_G.G.GAME)
	end
end

---@param store table
---@param fn fun(state: table)
function M.subscribe(store, fn)
	store:subscribe(fn)
end

--- Dispatch a store action and mirror onto G.GAME.
---@param store table
---@param action table
---@return table state
function M.dispatch(store, action)
	store:dispatch(action)
	M.sync_to_g(store)
	return store:get()
end

--- Adopt a game table as the authoritative store snapshot (new run / save load).
---@param store table
---@param game_table table
---@return table state
function M.bind_run(store, game_table)
	store:replace(game_table)
	M.sync_to_g(store)
	return store:get()
end

--- When legacy code assigns a fresh G.GAME table, adopt it into the store.
---@param store table|nil
function M.adopt_current_g_game(store)
	store = store or (_G.G and _G.G._store)
	if not store or not _G.G or not _G.G.GAME then return end
	if store:get() ~= _G.G.GAME then
		M.sync_from_g(store)
		M.sync_to_g(store)
	end
end

--- Headless tests: create store, bind WORD_GAME, mirror G.GAME.
function M.ensure_test_binding()
	if not _G.G then return nil end
	local word_game = package.loaded["word_game"]
	if not _G.G._store then
		_G.G._store = M.new()
	end
	if word_game and word_game._bind_store then
		word_game._bind_store(_G.G._store)
	end
	if _G.G.GAME then
		M.sync_from_g(_G.G._store)
	end
	M.sync_to_g(_G.G._store)
	local engine_boot = package.loaded["app.bootstrap.engine_services_boot"]
	if engine_boot and engine_boot.install then
		engine_boot.install()
	end
	return _G.G._store
end

return M
