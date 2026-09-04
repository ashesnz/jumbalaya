--[[ word_game/model/state.lua - Match-long Jumbalaya state on G.GAME.alpha ]]

local economy = require("word_game.config.economy")
local perks_cfg = require("word_game.config.perks")

local M = {}

function M.new()
	return {
		tokens = economy.STARTING_TOKENS,
		perks = {},
		perk_slots = perks_cfg.SLOT_COUNT,
		stats = {
			best_puzzle = nil,
			best_puzzle_score = 0,
			words_played = 0,
		},
		trade_used_this_hand = false,
		match_over = false,
		match_won = false,
	}
end

function M.get()
	if not G or not G.GAME then return nil end
	if G.RUN and G.RUN.active == false then return nil end
	G.GAME.alpha = G.GAME.alpha or M.new()
	return G.GAME.alpha
end

function M.tokens()
	local alpha = M.get()
	return alpha and alpha.tokens or 0
end

function M.add_tokens(amount)
	local alpha = M.get()
	if not alpha then return 0 end
	amount = math.floor(amount or 0)
	if amount <= 0 then return 0 end
	alpha.tokens = (alpha.tokens or 0) + amount
	return amount
end

function M.spend_tokens(amount)
	local alpha = M.get()
	if not alpha then return false end
	amount = math.floor(amount or 0)
	if amount <= 0 then return true end
	if (alpha.tokens or 0) < amount then return false end
	alpha.tokens = alpha.tokens - amount
	return true
end

function M.has_perk(key)
	-- Collected perks are cosmetic until scoring hooks are implemented.
	local alpha = M.get()
	if not alpha then return false end
	for _, perk in ipairs(alpha.perks) do
		if perk == key then return true end
	end
	return false
end

function M.rightmost_perk()
	local alpha = M.get()
	if not alpha then return nil end
	local slots = alpha.perk_slots or perks_cfg.SLOT_COUNT
	return alpha.perks[slots] or alpha.perks[#alpha.perks]
end

function M.add_perk(id)
	if not id then return false end
	local alpha = M.get()
	if not alpha then return false end
	alpha.perks = alpha.perks or {}
	local slots = alpha.perk_slots or perks_cfg.SLOT_COUNT
	if #alpha.perks >= slots then return false end
	alpha.perks[#alpha.perks + 1] = id
	return true
end

function M.ensure_stats()
	local alpha = M.get()
	if not alpha then return nil end
	alpha.stats = alpha.stats or {}
	local stats = alpha.stats
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
