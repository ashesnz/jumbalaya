--[[
	word_game/model/run/scope.lua - Run lifecycle boundary for store and run caches.

	Core: jumbalaya_core.store.default_state (teardown reset)
	Store: bind_run / replace via store_sync; RUN_STATE_INIT on new run
	Presentation: none (teardown hooks notify UI via install.lua subscribers)

	Every new run must pass through this module so stale UI bindings, module
	caches, and live_game().ARGS mirrors cannot leak across runs.
]]

local live_game = require("word_game.model.live_game")

local game_access = require("word_game.model.game_access")
local store_sync = require("app.bootstrap.store_sync")
local BridgeRuntime = require("app.runtime")
local CoreStore = require("jumbalaya_core.store")

local M = {}

local teardown_hooks = {}

local RUN_ARG_DEFAULTS = {
	deck_left_count = 0,
}

local function ensure_run_table()
	live_game().RUN = live_game().RUN or { generation = 0, active = false }
	return live_game().RUN
end

function M.on_teardown(name, fn)
	if type(name) ~= "string" or name == "" then
		error("RunScope.on_teardown requires a hook name")
	end
	if type(fn) ~= "function" then
		error("RunScope.on_teardown requires a function for " .. name)
	end
	teardown_hooks[#teardown_hooks + 1] = { name = name, fn = fn }
end

function M.generation()
	return (live_game().ARGS and live_game().ARGS.run_generation) or (live_game().RUN and live_game().RUN.generation) or 0
end

function M.is_current(gen)
	return gen ~= nil and gen == M.generation()
end

function M.is_active()
	local run = live_game().RUN
	return run and run.active and game_access.get() ~= nil
end

function M.with_generation(gen, fn)
	return function(...)
		if not M.is_current(gen) then
			return true
		end
		return fn(...)
	end
end

function M.reset_args()
	live_game().ARGS = live_game().ARGS or {}
	live_game().ARGS.run_generation = (live_game().ARGS.run_generation or 0) + 1
	for key, value in pairs(RUN_ARG_DEFAULTS) do
		live_game().ARGS[key] = value
	end
	live_game().ARGS.pending_layout = nil
	live_game().ARGS.run_snapshot = nil
	live_game().ARGS.spin = { amount = 0, real = 0, eased = 0 }
	if live_game().ARGS.score_intensity then
		live_game().ARGS.score_intensity.earned_score = 0
		live_game().ARGS.score_intensity.required_score = 0
	end
	local run = ensure_run_table()
	run.generation = live_game().ARGS.run_generation
end

function M.reset_globals()
	live_game().letter_inventory = {}
	live_game().letter_card_id = 0
	if live_game().LIVE then
		local wipe_card = live_game().screenwipecard
		live_game().LIVE.CARD = {}
		if wipe_card then
			live_game().LIVE.CARD[#live_game().LIVE.CARD + 1] = wipe_card
		end
		live_game().LIVE.CARDAREA = {}
	end
	live_game().SIDEBAR_HUD = nil
	if live_game().pattern_row then
		if live_game().pattern_row.reset_run then
			pcall(live_game().pattern_row.reset_run)
		else
			live_game().pattern_row.area = nil
		end
	end
	if live_game().HAND_CLEAR_OVERLAY and live_game().HAND_CLEAR_OVERLAY.remove then
		pcall(function() live_game().HAND_CLEAR_OVERLAY:remove() end)
	end
	live_game().HAND_CLEAR_OVERLAY = nil
	if live_game().FIRST_PLAY_TUTORIAL_OVERLAY and live_game().FIRST_PLAY_TUTORIAL_OVERLAY.remove then
		pcall(function() live_game().FIRST_PLAY_TUTORIAL_OVERLAY:remove() end)
	end
	live_game().FIRST_PLAY_TUTORIAL_OVERLAY = nil
end

function M.teardown()
	local run = ensure_run_table()
	run.active = false

	for i = #teardown_hooks, 1, -1 do
		local hook = teardown_hooks[i]
		local ok, err = pcall(hook.fn)
		if not ok and live_game().DEBUG then
			print("RunScope teardown hook failed:", hook.name, err)
		end
	end

	M.reset_globals()
	local store = BridgeRuntime.store()
	if store then
		store_sync.replace(store, CoreStore.default_state())
	end
	live_game().GAME = nil
end

--- Bind a snapshot without starting a full run (e.g. main menu deck preview).
function M.bind_snapshot(game_table)
	if type(game_table) ~= "table" then
		error("RunScope.bind_snapshot requires a game table")
	end
	local store = BridgeRuntime.store()
	if not store then
		error("RunScope.bind_snapshot requires WORD_GAME.store()")
	end
	store_sync.bind_run(store, game_table)
	local state = game_access.get()
	live_game().GAME = state
	return state
end

function M.init_new_run_state()
	local store = BridgeRuntime.store()
	if store then
		store_sync.dispatch(store, { type = "RUN_STATE_INIT" })
	end
end

function M.begin_run(game_table, opts)
	opts = opts or {}
	if type(game_table) ~= "table" then
		error("RunScope.begin_run requires a game table")
	end
	local current = game_access.get()
	if not opts.from_save and current ~= nil and current == game_table then
		error("RunScope.begin_run requires a fresh run table for new runs")
	end
	M.reset_args()
	game_table.run_generation = M.generation()
	local store = BridgeRuntime.store()
	if not store then
		error("RunScope.begin_run requires WORD_GAME.store()")
	end
	store_sync.bind_run(store, game_table)
	local run = ensure_run_table()
	run.active = true
	run.from_save = opts.from_save or false
	if not opts.from_save then
		M.init_new_run_state()
	end
	local state = game_access.get()
	live_game().GAME = state
	return state
end

function M.assign_game(game_table, opts)
	return M.begin_run(game_table, opts)
end

return M
