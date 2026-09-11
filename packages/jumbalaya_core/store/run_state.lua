--[[ packages/jumbalaya_core/store/run_state.lua - Run state schema and helpers (no G) ]]

local economy = require("jumbalaya_core.config.gameplay.economy")
local perks_cfg = require("jumbalaya_core.config.perks")

local M = {}

function M.new(opts)
	opts = opts or {}
	return {
		tokens = opts.tokens or economy.STARTING_TOKENS,
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

function M.has_perk(rs, key)
	if not rs then return false end
	for _, perk in ipairs(rs.perks or {}) do
		if perk == key then return true end
	end
	return false
end

function M.perk_flags(rs)
	return {
		wide_hand = M.has_perk(rs, "wide_hand"),
		combo_starter = M.has_perk(rs, "combo_starter"),
		combo_master = M.has_perk(rs, "combo_master"),
		combo_keeper = M.has_perk(rs, "combo_keeper"),
		letter_boost = M.has_perk(rs, "letter_boost"),
		red_rush = M.has_perk(rs, "red_rush"),
		vowel_veil = M.has_perk(rs, "vowel_veil"),
		long_word = M.has_perk(rs, "long_word"),
		extra_redraw = M.has_perk(rs, "extra_redraw"),
		time_bank = M.has_perk(rs, "time_bank"),
		speed_demon = M.has_perk(rs, "speed_demon"),
		time_saver = M.has_perk(rs, "time_saver"),
		last_second = M.has_perk(rs, "last_second"),
		risky_business = M.has_perk(rs, "risky_business"),
		greedy = M.has_perk(rs, "greedy"),
	}
end

function M.tokens(rs)
	return rs and rs.tokens or 0
end

function M.add_tokens(rs, amount)
	if not rs then return 0 end
	amount = math.floor(amount or 0)
	if amount <= 0 then return 0 end
	rs.tokens = (rs.tokens or 0) + amount
	return amount
end

function M.spend_tokens(rs, amount)
	if not rs then return false end
	amount = math.floor(amount or 0)
	if amount <= 0 then return true end
	if (rs.tokens or 0) < amount then return false end
	rs.tokens = rs.tokens - amount
	return true
end

return M
