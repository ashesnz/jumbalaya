--[[ word_game/model/run_scope.lua - Run lifecycle boundary for G.GAME and run caches.

	Every new run must pass through this module so stale UI bindings, module
	caches, and G.ARGS mirrors cannot leak across runs.
]]

local M = {}

local teardown_hooks = {}

local RUN_ARG_DEFAULTS = {
	deck_left_count = 0,
}

local function ensure_run_table()
	G.RUN = G.RUN or { generation = 0, active = false }
	return G.RUN
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
	return (G.ARGS and G.ARGS.run_generation) or (G.RUN and G.RUN.generation) or 0
end

function M.is_current(gen)
	return gen ~= nil and gen == M.generation()
end

function M.is_active()
	local run = G.RUN
	return run and run.active and G.GAME ~= nil
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
	G.ARGS = G.ARGS or {}
	G.ARGS.run_generation = (G.ARGS.run_generation or 0) + 1
	for key, value in pairs(RUN_ARG_DEFAULTS) do
		G.ARGS[key] = value
	end
	G.ARGS.pending_layout = nil
	G.ARGS.table_discard_board_draw = nil
	G.ARGS.run_snapshot = nil
	G.ARGS.spin = { amount = 0, real = 0, eased = 0 }
	if G.ARGS.score_intensity then
		G.ARGS.score_intensity.earned_score = 0
		G.ARGS.score_intensity.required_score = 0
	end
	local run = ensure_run_table()
	run.generation = G.ARGS.run_generation
end

local function destroy_host(global_key)
	local host = G[global_key]
	if host and host.remove then
		pcall(function() host:remove() end)
	end
	G[global_key] = nil
end

function M.reset_globals()
	G.playing_cards = {}
	G.playing_card = 0
	if G.LIVE then
		local wipe_card = G.screenwipecard
		G.LIVE.CARD = {}
		if wipe_card then
			G.LIVE.CARD[#G.LIVE.CARD + 1] = wipe_card
		end
		G.LIVE.CARDAREA = {}
	end
	G.word_sidebar_uibox = nil
	if G.placement_table then
		if G.placement_table.reset_run then
			pcall(G.placement_table.reset_run)
		else
			G.placement_table.area = nil
		end
	end
	destroy_host("player_host")
	destroy_host("ally_host")
	destroy_host("guest_host")
	if G.HAND_CLEAR_OVERLAY and G.HAND_CLEAR_OVERLAY.remove then
		pcall(function() G.HAND_CLEAR_OVERLAY:remove() end)
	end
	G.HAND_CLEAR_OVERLAY = nil
end

function M.teardown()
	local run = ensure_run_table()
	run.active = false

	for i = #teardown_hooks, 1, -1 do
		local hook = teardown_hooks[i]
		local ok, err = pcall(hook.fn)
		if not ok and G.DEBUG then
			print("RunScope teardown hook failed:", hook.name, err)
		end
	end

	M.reset_globals()
	G.GAME = nil
end

function M.init_new_run_state()
	local run_state = require("word_game.model.state")
	G.GAME.run_state = run_state.new()
end

function M.begin_run(game_table, opts)
	opts = opts or {}
	if type(game_table) ~= "table" then
		error("RunScope.begin_run requires a game table")
	end
	if not opts.from_save and G.GAME ~= nil and G.GAME == game_table then
		error("RunScope.begin_run requires a fresh G.GAME table for new runs")
	end
	M.reset_args()
	G.GAME = game_table
	local run_state = require("word_game.model.state")
	run_state.migrate_legacy_field(G.GAME)
	G.GAME.run_generation = M.generation()
	local run = ensure_run_table()
	run.active = true
	if not opts.from_save then
		M.init_new_run_state()
	end
	return G.GAME
end

function M.assign_game(game_table, opts)
	return M.begin_run(game_table, opts)
end

return M
