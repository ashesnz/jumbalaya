--[[
	word_game/model/game_access.lua - Read/write run snapshot via WORD_GAME.store().

	Core: jumbalaya_core.store reducers (dispatched through store_sync)
	Store: get / patch / dispatch / mutate on GameRunState (types/store.lua)
	Presentation: none — callers emit after store writes
]]

local store_sync = require("app.bootstrap.store_sync")
local runtime = require("app.runtime")

local M = {}

local function store()
	return runtime.store()
end

function M.get()
	local s = store()
	if s then
		return s:get()
	end
	return nil
end

function M.word_round()
	local game = M.get()
	return game and game.word_round
end

function M.dispatch(action)
	local s = store()
	if not s or not action then
		return M.get()
	end
	return store_sync.dispatch(s, action)
end

function M.patch(fields)
	local s = store()
	if not s or not fields then
		return M.get()
	end
	return store_sync.dispatch(s, { type = "GAME_PATCH", patch = fields })
end

--- In-place mutation of the live store snapshot (same table as store:get()).
function M.mutate(fn)
	local game = M.get()
	if not game or not fn then return game end
	fn(game)
	return game
end

return M
