--[[ word_game/model/run/state.lua - Match-long run state on G.GAME.run_state ]]

local core_run_state = require("jumbalaya_core.store.run_state")

local M = {}

function M.new()
	return core_run_state.new()
end

--- Migrates legacy save field `G.GAME.alpha` → `run_state` once per load.
function M.migrate_legacy_field(game)
	if not game or type(game) ~= "table" then return end
	if game.run_state then
		game.alpha = nil
		return
	end
	if game.alpha then
		game.run_state = game.alpha
		game.alpha = nil
	end
end

function M.get()
	if not G or not G.GAME then return nil end
	if G.RUN and G.RUN.active == false then return nil end
	M.migrate_legacy_field(G.GAME)
	G.GAME.run_state = G.GAME.run_state or M.new()
	return G.GAME.run_state
end

function M.tokens()
	return core_run_state.tokens(M.get())
end

function M.add_tokens(amount)
	return core_run_state.add_tokens(M.get(), amount)
end

function M.spend_tokens(amount)
	return core_run_state.spend_tokens(M.get(), amount)
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
	rs.perks = rs.perks or {}
	local slots = rs.perk_slots or perks_cfg.SLOT_COUNT
	if #rs.perks >= slots then return false end
	rs.perks[#rs.perks + 1] = id
	return true
end

function M.ensure_stats()
	local rs = M.get()
	if not rs then return nil end
	rs.stats = rs.stats or {}
	local stats = rs.stats
	stats.words_played = stats.words_played or 0
	stats.best_puzzle_score = stats.best_puzzle_score or 0
	return stats
end

function M.record_word_played()
	local stats = M.ensure_stats()
	if not stats then return end
	stats.words_played = (stats.words_played or 0) + 1
end

function M.record_puzzle_score(pattern, score)
	local stats = M.ensure_stats()
	if not stats then return end
	score = math.floor(tonumber(score) or 0)
	if score <= 0 then return end
	if score <= (stats.best_puzzle_score or 0) then return end
	if type(pattern) == "string" and pattern ~= "" then
		stats.best_puzzle = pattern
	else
		stats.best_puzzle = stats.best_puzzle or "Puzzle"
	end
	stats.best_puzzle_score = score
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
	local wr = G and G.GAME and G.GAME.word_round
	local j = wr and wr.jumble
	if not j then return end
	local score = math.floor((j.puzzle_points or 0) * (j.puzzle_multi or 1.0))
	M.record_puzzle_score(current_puzzle_label(j), score)
end

return M
