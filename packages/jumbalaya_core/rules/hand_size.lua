--[[ packages/jumbalaya_core/rules/hand_size.lua - Hand size from base + perks (no G) ]]

local hand_config = require("jumbalaya_core.config.gameplay.hand")

local M = {}

function M.base_size(override)
	return override or hand_config.TABLE_HAND_SIZE
end

function M.bonus(perk_flags)
	if perk_flags and perk_flags.wide_hand then
		return 1
	end
	return 0
end

function M.get(base_size, perk_flags)
	return M.base_size(base_size) + M.bonus(perk_flags)
end

return M
