--[[ word_game/model/almanac.lua - Account-wide collection log ]]

local perks_cfg = require("word_game.config.perks")
local upgrades_cfg = require("word_game.config.upgrades")
local wild_cfg = require("word_game.config.wildcards")

local M = {}

local function profile()
	if not G or not G.PROFILES or not G.SETTINGS then return nil end
	local p = G.PROFILES[G.SETTINGS.profile]
	if not p then return nil end
	p.almanac = p.almanac or {
		perks = {},
		upgrades = {},
		wildcards = {},
		words = {},
		unlocks = {},
	}
	return p.almanac
end

function M.discover(kind, key)
	local log = profile()
	if not log or not key then return end
	log[kind] = log[kind] or {}
	log[kind][key] = true
end

function M.discover_word(word)
	local log = profile()
	if not log or not word then return end
	log.words[word] = true
end

function M.unlock(flag)
	local log = profile()
	if not log or not flag then return end
	log.unlocks[flag] = true
end

function M.has_unlock(flag)
	local log = profile()
	return log and log.unlocks[flag] == true
end

function M.counts()
	local log = profile() or { perks = {}, upgrades = {}, wildcards = {} }
	local function tally(seen, order)
		local have, total = 0, #order
		for _, key in ipairs(order) do
			if seen[key] then have = have + 1 end
		end
		return have, total
	end
	local p_h, p_t = tally(log.perks or {}, perks_cfg.ORDER)
	local u_h, u_t = tally(log.upgrades or {}, upgrades_cfg.ORDER)
	local w_h, w_t = tally(log.wildcards or {}, wild_cfg.ORDER)
	return {
		perks = { have = p_h, total = p_t },
		upgrades = { have = u_h, total = u_t },
		wildcards = { have = w_h, total = w_t },
	}
end

function M.on_match_event(kind, payload)
	if kind == "sweep" then
		M.unlock("played_sweep")
	elseif kind == "perk" then
		M.discover("perks", payload)
	elseif kind == "upgrade" then
		M.discover("upgrades", payload)
	elseif kind == "wildcard" then
		M.discover("wildcards", payload)
	elseif kind == "word" then
		M.discover_word(payload)
	end
end

return M
