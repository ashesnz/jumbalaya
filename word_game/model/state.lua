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
			best_word = nil,
			best_word_score = 0,
			highest_boost = 0,
			words_played = 0,
			sweeps = 0,
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

return M
