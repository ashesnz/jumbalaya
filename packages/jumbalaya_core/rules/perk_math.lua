--[[ packages/jumbalaya_core/rules/perk_math.lua - Pure perk scoring math (no G) ]]

local M = {}

---@class PerkFlags
---@field combo_starter boolean|nil
---@field combo_master boolean|nil

function M.round_multi(value)
	return math.floor(value * 10 + 0.5) / 10
end

function M.starting_puzzle_multi(perks)
	perks = perks or {}
	if perks.combo_starter then return 1.2 end
	return 1.0
end

function M.combo_step(perks)
	perks = perks or {}
	if perks.combo_master then return 0.3 end
	return 0.2
end

function M.puzzle_multi_for_word_count(count, perks)
	count = count or 0
	perks = perks or {}
	if count < 1 then
		return M.round_multi(M.starting_puzzle_multi(perks))
	end
	local base = M.starting_puzzle_multi(perks)
	if count < 2 then
		return M.round_multi(base)
	end
	return M.round_multi(base + (count - 1) * M.combo_step(perks))
end

return M
