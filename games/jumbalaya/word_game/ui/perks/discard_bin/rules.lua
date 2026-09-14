--[[ word_game/ui/perks/discard_bin/rules.lua - Voucher discard unlock and visibility rules ]]

local game = require("word_game.ui.util.game_runtime").game

local facade = require("word_game.ui.facade")
local felt = require("word_game.ui.layout.felt")
local round_config = require("jumbalaya_core.config.gameplay.round")
local run_state = facade.run_state()

local M = {
	DISCARD_PERK_ID = "discard_bin",
}

local function perk_stamp_imprint_count()
	local stamp = WORD_GAME_UI and WORD_GAME_UI.PerkStamp
	if stamp and stamp.imprint_count then
		return stamp.imprint_count()
	end
	return 0
end

function M.voucher_discard_unlocked()
	local rs = run_state.get()
	if rs and #(rs.perks or {}) >= 1 then
		return true
	end
	return perk_stamp_imprint_count() >= 1
end

function M.max_fills()
	return round_config.VOUCHER_DISCARDS_PER_HAND
end

function M.uses_table_draw()
	if game().STATE ~= game().STATES.TABLE_BOARD then return false end
	if felt.is_boss_sequence() then return false end
	return true
end

function M.end_run_button_visible()
	if game().STAGE ~= game().STAGES.RUN then return false end
	if felt.is_boss_sequence() then return false end
	return game().STATE == game().STATES.TABLE_BOARD
end

return M
