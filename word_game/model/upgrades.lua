--[[ word_game/model/upgrades.lua - Attach and resolve per-card Upgrades ]]

local upgrades_cfg = require("word_game.config.upgrades")
local deck = require("word_game.model.cards.deck")

local M = {}

function M.get(card)
	return nil
end

function M.attach(card, key)
	return false
end

function M.label(card)
	local key = M.get(card)
	local def = key and upgrades_cfg.get(key)
	return def and def.abbrev or nil
end

function M.is_steel(card)
	return M.get(card) == "steel"
end

function M.is_glass(card)
	return M.get(card) == "glass"
end

function M.eligible_cards(upgrade_key)
	local def = upgrades_cfg.get(upgrade_key)
	if not def then return {} end
	local out = {}
	deck.iter_cards(function(card)
		local current = M.get(card)
		if not current then
			out[#out + 1] = card
		elseif current ~= upgrade_key then
			local cur = upgrades_cfg.get(current)
			-- Re-upgrade allowed: same card, different (usually higher) upgrade
			if not cur or (def.tier or 0) >= (cur.tier or 0) or upgrade_key ~= current then
				out[#out + 1] = card
			end
		end
	end)
	return out
end

function M.resolve_after_play(cards)
	return { shattered = {}, steel = {} }
end

return M
