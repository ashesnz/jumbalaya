--[[
	app/bootstrap/store_sync.lua - Store factory and test binding helpers.
]]

local CoreStore = require("jumbalaya_core.store")
local default_state = require("jumbalaya_core.store.default_state")
local runtime = require("app.runtime")

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

--- Replace store from a saved snapshot.
---@param store table
---@param snapshot table
function M.restore_snapshot(store, snapshot)
	if not store or not snapshot then return end
	store:replace(snapshot.GAME or snapshot)
end

--- Headless tests: ensure store is bound to WORD_GAME.
function M.ensure_test_binding()
	local shell = runtime.game()
	if not shell then return nil end
	local word_game = package.loaded["word_game"]
	local store = runtime.store()
	if not store then
		store = M.new()
		if word_game and word_game._bind_store then
			word_game._bind_store(store)
		end
	end
	if shell.dealt_letters or shell.draw_pile then
		require("word_game.model.piles").sync_hosts_to_store(store)
	end
	local engine_boot = package.loaded["app.bootstrap.engine_services_boot"]
	if engine_boot and engine_boot.install then
		engine_boot.install()
	end
	local shell_bind = package.loaded["app.bootstrap.shell_bind"]
	if shell_bind and shell_bind.install then
		shell_bind.install()
	elseif not package.loaded["app.bootstrap.shell_bind"] then
		require("app.bootstrap.shell_bind").install()
	end
	return store
end

return M
