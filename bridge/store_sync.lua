--[[
	bridge/store_sync.lua - Phase 8 store bridge (G.GAME mirror retired in PR-2).

	Contract:
	- The store owns run snapshot state.
	- New code uses WORD_GAME.store() / game_access.
	- legacy_mirror_* helpers remain for headless tests without a bound store.
]]

local CoreStore = require("jumbalaya_core.store")
local default_state = require("jumbalaya_core.store.default_state")
local runtime = require("bridge.runtime")

local M = {}

---@return table store GameStore instance
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
end

---@param store table
---@param patch table
function M.patch(store, patch)
	store:patch(patch)
end

--- Retired in PR-2: store is authoritative; no G.GAME mirror.
function M.sync_to_g(_store) end

--- Clear legacy G.GAME slot on run teardown (bridge-only).
function M.clear_g_mirror()
	if _G.G then
		_G.G.GAME = nil
	end
end

--- Legacy mirror read when store is not bound (headless tests; bridge-only).
function M.legacy_mirror_get()
	if _G.G then
		return _G.G.GAME
	end
	return nil
end

--- Legacy mirror patch when store is not bound (headless tests; bridge-only).
---@param fields table
function M.legacy_mirror_patch(fields)
	local game = M.legacy_mirror_get()
	if not game or not fields then return game end
	for key, value in pairs(fields) do
		game[key] = value
	end
	return game
end

--- Bootstrap helper: adopt legacy G.GAME table into store (tests / one-time boot).
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

--- Dispatch a store action.
---@param store table
---@param action table
---@return table state
function M.dispatch(store, action)
	store:dispatch(action)
	return store:get()
end

--- Adopt a game table as the authoritative store snapshot (new run / save load).
---@param store table
---@param game_table table
---@return table state
function M.bind_run(store, game_table)
	store:replace(game_table)
	return store:get()
end

--- Retired in PR-2.
function M.adopt_current_g_game(_store) end

--- Replace store from a saved snapshot.
---@param store table
---@param snapshot table
function M.restore_snapshot(store, snapshot)
	if not store or not snapshot then return end
	store:replace(snapshot.GAME or snapshot)
end

--- Headless tests: create store, bind WORD_GAME.
function M.ensure_test_binding()
	if not _G.G then return nil end
	local word_game = package.loaded["word_game"]
	local store = runtime.store()
	if not store then
		store = M.new()
		if word_game and word_game._bind_store then
			word_game._bind_store(store)
		end
	end
	if _G.G.GAME then
		M.sync_from_g(store)
	end
	if _G.G.dealt_letters or _G.G.draw_pile then
		require("bridge.pile_sync").sync_areas_to_store(store)
	end
	local engine_boot = package.loaded["app.bootstrap.engine_services_boot"]
	if engine_boot and engine_boot.install then
		engine_boot.install()
	end
	return store
end

return M
