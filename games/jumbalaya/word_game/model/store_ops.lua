--[[
	word_game/model/store_ops.lua - Store factory/dispatch for model glue (no app/ imports).

	Core: jumbalaya_core.store
	Store: bind_run, dispatch, replace, restore_snapshot
	Presentation: none
]]

local CoreStore = require("jumbalaya_core.store")
local default_state = require("jumbalaya_core.store.default_state")
local immutable = require("jumbalaya_core.store.immutable")
local shell = require("jumbalaya-engine.shell")

local M = {}

--- @type table<any, function>
local alias_sync_hooks = setmetatable({}, { __mode = "k" })

local function sync_game_alias(state)
	local game = shell.game()
	if game then
		game.GAME = state
	end
end

function M.get_state(store)
	if not store then return nil end
	return store:get()
end

function M.install_game_alias_sync(store)
	if not store or alias_sync_hooks[store] then
		return
	end
	local function on_state(state)
		sync_game_alias(state)
	end
	store:subscribe(on_state)
	alias_sync_hooks[store] = on_state
	sync_game_alias(store:get())
end

function M.new(initial)
	return CoreStore.new(initial or default_state.new())
end

function M.default_state()
	return default_state.new()
end

function M.store()
	return shell.store()
end

function M.get()
	local s = M.store()
	return s and s:get()
end

function M.dispatch(store, action)
	store = store or M.store()
	if not store or not action then
		return M.get()
	end
	store:dispatch(action)
	return store:get()
end

function M.patch(store, fields)
	store = store or M.store()
	if not store or not fields then
		return M.get()
	end
	return M.dispatch(store, { type = "GAME_PATCH", patch = fields })
end

function M.replace(store, state)
	if store and state then
		store:replace(state)
		sync_game_alias(store:get())
	end
end

function M.bind_run(store, game_table)
	store = store or M.store()
	if not store or not game_table then
		return M.get()
	end
	M.install_game_alias_sync(store)
	store:replace(game_table)
	return store:get()
end

function M.restore_snapshot(store, snapshot)
	if not store or not snapshot then return end
	store:replace(snapshot.GAME or snapshot)
end

function M.subscribe(store, fn)
	if store then
		store:subscribe(fn)
	end
end

--- Copy-on-write mutation for legacy glue that still edits nested tables directly.
function M.mutate(fn)
	local store = M.store()
	if not store or not fn then
		return M.get()
	end
	local next = immutable.shallow_state(store:get())
	fn(next)
	store:replace(next)
	return next
end

--- Headless tests: ensure store + shell bindings exist.
function M.ensure_test_binding()
	local game = shell.game()
	if not game then return nil end

	local word_game = package.loaded["word_game"]
	local store = M.store()
	if not store then
		store = M.new()
		if word_game and word_game._bind_store then
			word_game._bind_store(store)
		end
	end
	M.install_game_alias_sync(store)

	if game.dealt_letters or game.draw_pile then
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
