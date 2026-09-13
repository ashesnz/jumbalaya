--[[
	word_game/model/run/state.lua - Match-long economy state (tokens, perks, stats).

	Core: jumbalaya_core.store.run_state
	Store: run_state subtree; RUN_STATE_* dispatches
	Presentation: tokens_changed, perk_acquired (via install subscribers)
]]

local live_game = require("word_game.model.live_game")

local perks_cfg = require("word_game.config.perks")
local core_run_state = require("jumbalaya_core.store.run_state")
local game_access = require("word_game.model.game_access")

local M = {}

function M.new()
	return core_run_state.new()
end

function M.get()
	local game = game_access.get()
	if not game then return nil end
	local run = live_game().RUN
	if run and run.active == false then return nil end
	if not game.run_state then
		game_access.dispatch({ type = "RUN_STATE_INIT" })
		game = game_access.get()
	end
	return game and game.run_state
end

function M.tokens()
	return core_run_state.tokens(M.get())
end

function M.add_tokens(amount)
	amount = math.floor(amount or 0)
	if amount <= 0 then return 0 end
	local before = M.tokens()
	game_access.dispatch({ type = "RUN_STATE_ADD_TOKENS", amount = amount })
	return M.tokens() - before
end

function M.spend_tokens(amount)
	amount = math.floor(amount or 0)
	if amount <= 0 then return true end
	if M.tokens() < amount then return false end
	game_access.dispatch({ type = "RUN_STATE_SPEND_TOKENS", amount = amount })
	return true
end

function M.has_perk(key)
	return core_run_state.has_perk(M.get(), key)
end

function M.rightmost_perk()
	local rs = M.get()
	if not rs then return nil end
	local slots = rs.perk_slots or perks_cfg.SLOT_COUNT
	return rs.perks[slots] or rs.perks[#rs.perks]
end

function M.add_perk(id)
	if not id then return false end
	local rs = M.get()
	if not rs then return false end
	local slots = rs.perk_slots or perks_cfg.SLOT_COUNT
	if #(rs.perks or {}) >= slots then return false end
	game_access.dispatch({ type = "RUN_STATE_ADD_PERK", id = id })
	return true
end

function M.record_word_played()
	if not M.get() then return end
	game_access.dispatch({ type = "RUN_STATE_RECORD_WORD_PLAYED" })
end

function M.record_puzzle_score(pattern, score)
	game_access.dispatch({
		type = "RUN_STATE_RECORD_PUZZLE_SCORE",
		pattern = pattern,
		score = score,
	})
end

local function current_puzzle_label(j)
	if not j then return nil end
	if type(j.pattern) == "string" and j.pattern ~= "" then
		return j.pattern
	end
	local puzzle = j.puzzle
	if type(puzzle) ~= "table" then return nil end
	if type(puzzle.display) == "string" and puzzle.display ~= "" then
		return puzzle.display
	end
	if type(puzzle.pattern) == "string" and puzzle.pattern ~= "" then
		return puzzle.pattern
	end
	return nil
end

--- If the current unbanked puzzle outscores the recorded best, keep it.
function M.record_current_jumble_if_best()
	local wr = game_access.word_round()
	local j = wr and wr.jumble
	if not j then return end
	local score = math.floor((j.puzzle_points or 0) * (j.puzzle_multi or 1.0))
	M.record_puzzle_score(current_puzzle_label(j), score)
end

return M
