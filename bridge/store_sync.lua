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

return M
