--[[ word_game/model/perks/voucher_discard.lua - Discard-bin allowance (rules only) ]]

local Presentation = require("word_game.model.presentation")
local round_config = require("word_game.config.gameplay.round")
local run_state = require("word_game.model.run.state")

local M = {}

local function write_used(count)
	count = math.max(0, count or 0)
	if G.GAME then
		G.GAME.voucher_discards_used = count
		G.GAME.discard_bin_count = count
	end
end

function M.used()
	if G.GAME and G.GAME.voucher_discards_used ~= nil then
		return G.GAME.voucher_discards_used
	end
	if G.GAME and G.GAME.discard_bin_count ~= nil then
		return G.GAME.discard_bin_count
	end
	return 0
end

function M.max_fills()
	return round_config.VOUCHER_DISCARDS_PER_HAND
end

function M.left()
	return math.max(0, M.max_fills() - M.used())
end

function M.unlocked()
	local rs = run_state.get()
	return rs and #(rs.perks or {}) >= 1
end

function M.reset()
	write_used(0)
	Presentation.emit("voucher_discard_ui_reset")
end

function M.can_discard_card(card)
	if not M.unlocked() or M.left() <= 0 then return false end
	if not card or card.REMOVED or card.area ~= G.hand then return false end
	if card.bonus_card or card.boss_temp then return false end
	return true
end

function M.record_discard()
	local used = M.used()
	if used >= M.max_fills() then return false end
	local from_left = M.left()
	write_used(used + 1)
	Presentation.emit("voucher_discard_recorded", from_left, M.left())
	return true
end

function M.stash_discarded_card(card)
	if not card or card.played_pool then return end
	card.discard_stash = true
	if card.states then
		card.states.visible = false
	end
end

function M.is_full()
	return M.used() >= M.max_fills()
end

return M
