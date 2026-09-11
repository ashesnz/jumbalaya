--[[ word_game/model/perks/registry.lua - Perk stamp rolls and selection (G glue over core) ]]

local cfg = require("word_game.config.perks")
local core = require("jumbalaya_core.perks.registry")

local M = {}

local function rand_float(key)
	if type(advance_seed) == "function" and G and G.GAME and G.GAME.seed_streams then
		return advance_seed(key)
	end
	return math.random()
end

local function rand_int(key, min, max)
	if max <= min then return min end
	local n = max - min + 1
	local idx = min + math.floor(rand_float(key) * n)
	if idx > max then idx = max end
	return idx
end

function M.roll_stamp_perk()
	local rs = require("word_game.model.run.state").get()
	return core.roll_stamp_perk({
		pool = cfg.POOL,
		perk_count = rs and #(rs.perks or {}) or 0,
		rand_int = rand_int,
		seed_prefix = cfg.RANDOM_SEED_PREFIX,
		by_id = cfg.by_id,
	})
end

function M.selected()
	return G.GAME and G.GAME.selected_perk
end

function M.apply_choice(perk)
	if not perk or not perk.id then return false end
	local entry = cfg.by_id(perk.id)
	if not entry then return false end
	local stored = {
		id = entry.id,
		name = entry.name,
		desc = entry.desc,
		pos = { x = entry.pos.x, y = entry.pos.y },
	}
	if G.GAME then
		G.GAME.selected_perk = stored
	end
	return true
end

function M.description_vars(center, profile)
	return core.description_vars(center, profile, cfg.DESCRIPTION_VARIABLES)
end

return M
