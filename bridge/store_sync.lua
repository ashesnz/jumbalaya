--[[
	bridge/store_sync.lua - Phase 0 store ↔ G.GAME compatibility shim.

	Contract (engine migration Phase 0–2):
	- The store owns run snapshot state during migration.
	- G.GAME is a mirror for legacy readers until Phase 7 removes G.
	- New code should use store APIs; do not write G.GAME directly once a
	  module has been migrated to dispatch through the store.

	Replaced by packages/jumbalaya-core/store in Phase 1+.
]]

local M = {}

---@class GameStore
---@field _state table
---@field _subscribers fun(state: table)[]

---@return GameStore
function M.new(initial)
	return {
		_state = initial or {},
		_subscribers = {},
	}
end

---@param store GameStore
---@return table
function M.get_state(store)
	return store._state
end

---@param store GameStore
---@param state table
function M.replace(store, state)
	store._state = state
	M.sync_to_g(store)
	M._notify(store)
end

--- Shallow-merge keys from patch into store state.
---@param store GameStore
---@param patch table
function M.patch(store, patch)
	for key, value in pairs(patch) do
		store._state[key] = value
	end
	M.sync_to_g(store)
	M._notify(store)
end

--- Mirror store state onto G.GAME for legacy modules.
---@param store GameStore
function M.sync_to_g(store)
	if _G.G then
		_G.G.GAME = store._state
	end
end

--- Bootstrap helper: adopt the current G.GAME table as store state.
--- Use only at boot or in tests bridging legacy setup code.
---@param store GameStore
function M.sync_from_g(store)
	if _G.G and _G.G.GAME then
		store._state = _G.G.GAME
	end
end

---@param store GameStore
---@param fn fun(state: table)
function M.subscribe(store, fn)
	store._subscribers[#store._subscribers + 1] = fn
end

---@param store GameStore
function M._notify(store)
	for _, fn in ipairs(store._subscribers) do
		fn(store._state)
	end
end

return M
