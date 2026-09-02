--[[ word_game/model/perk.lua - Perk stamp rolls and selection ]]

local cfg = require("word_game.config.perks")

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

local function copy_perk(entry)
	return {
		id = entry.id,
		name = entry.name,
		desc = entry.desc,
		pos = { x = entry.pos.x, y = entry.pos.y },
	}
end

function M.roll_stamp_perk()
	local pool = cfg.POOL
	if #pool == 0 then return nil end
	local idx = rand_int(cfg.RANDOM_SEED_PREFIX .. "stamp", 1, #pool)
	return copy_perk(pool[idx])
end

function M.selected()
	return G.GAME and G.GAME.selected_perk
end

function M.apply_choice(perk)
	if not perk or not perk.id then return false end
	local entry = cfg.by_id(perk.id)
	if not entry then return false end
	local stored = copy_perk(entry)
	if G.GAME then
		G.GAME.selected_perk = stored
	end
	return true
end

function M.description_vars(center, profile)
	local condition = center and center.unlock_condition or {}
	local stats = profile and profile.career_stats or {}
	local variables = cfg.DESCRIPTION_VARIABLES[center and center.name]
	if variables then
		local result = { condition.extra }
		for _, key in ipairs(variables) do
			if key == "v_blank" then
				local usage = profile and profile.bonus_usage and profile.bonus_usage[key]
				result[#result + 1] = usage and usage.count or 0
			else
				result[#result + 1] = stats[key]
			end
		end
		return result
	end
	return nil
end

return M
