--[[ word_game/model/perks/voucher_discard.lua - Discard-bin allowance (G glue over core) ]]

local live_game = require("word_game.model.live_game")

local Presentation = require("word_game.model.presentation")
local run_state = require("word_game.model.run.state")
local core = require("jumbalaya_core.rules.voucher_discard")
local game_access = require("word_game.model.game_access")

local M = {}

local function write_used(count)
	game_access.dispatch({ type = "SET_VOUCHER_DISCARDS_USED", count = math.max(0, count or 0) })
end

function M.used()
	local game = game_access.get()
	if game and game.voucher_discards_used ~= nil then
		return game.voucher_discards_used
	end
	if game and game.discard_bin_count ~= nil then
		return game.discard_bin_count
	end
	return 0
end

function M.max_fills()
	return core.max_fills()
end

function M.left()
	return core.left(M.used())
end

function M.unlocked()
	local rs = run_state.get()
	return core.unlocked(rs and #(rs.perks or {}) or 0)
end

function M.reset()
	write_used(0)
	Presentation.emit("voucher_discard_ui_reset")
end

function M.can_discard_card(card)
	local rs = run_state.get()
	return core.can_discard_card(card, {
		perk_count = rs and #(rs.perks or {}) or 0,
		used = M.used(),
		hand_area = live_game().dealt_letters,
	})
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
	return core.is_full(M.used())
end

return M
