--[[ packages/jumbalaya_core/perks/registry.lua - Perk stamp rolls (no G) ]]

local perks_cfg = require("jumbalaya_core.config.perks")

local M = {}

local function copy_perk(entry)
	return {
		id = entry.id,
		name = entry.name,
		desc = entry.desc,
		pos = { x = entry.pos.x, y = entry.pos.y },
	}
end

function M.roll_stamp_perk(opts)
	opts = opts or {}
	local pool = opts.pool or perks_cfg.POOL
	if #pool == 0 then return nil end
	local perk_count = opts.perk_count or 0
	if perk_count == 0 then
		local first = (opts.by_id and opts.by_id("discard_bin")) or perks_cfg.by_id("discard_bin") or pool[1]
		if first then return copy_perk(first) end
	end
	local rand_int = opts.rand_int
	if not rand_int then return copy_perk(pool[1]) end
	local prefix = opts.seed_prefix or perks_cfg.RANDOM_SEED_PREFIX
	local idx = rand_int(prefix .. "stamp", 1, #pool)
	return copy_perk(pool[idx])
end

function M.description_vars(center, profile, description_variables)
	local condition = center and center.unlock_condition or {}
	local stats = profile and profile.career_stats or {}
	local variables = description_variables and description_variables[center and center.name]
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
