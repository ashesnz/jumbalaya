--[[ packages/jumbalaya_core/rules/voucher_discard.lua - Discard-bin allowance rules (no G) ]]

local round_config = require("jumbalaya_core.config.gameplay.round")

local M = {}

function M.max_fills()
	return round_config.VOUCHER_DISCARDS_PER_HAND
end

function M.left(used)
	used = math.max(0, used or 0)
	return math.max(0, M.max_fills() - used)
end

function M.unlocked(perk_count)
	return (perk_count or 0) >= 1
end

function M.can_discard_card(card, opts)
	opts = opts or {}
	if not M.unlocked(opts.perk_count) or M.left(opts.used or 0) <= 0 then
		return false
	end
	if not card or card.REMOVED then return false end
	if opts.hand_area and card.area ~= opts.hand_area then return false end
	if card.bonus_card or card.boss_temp then return false end
	return true
end

function M.is_full(used)
	return (used or 0) >= M.max_fills()
end

return M
