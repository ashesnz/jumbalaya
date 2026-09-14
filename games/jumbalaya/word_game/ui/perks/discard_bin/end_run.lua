--[[ word_game/ui/perks/discard_bin/end_run.lua - End Run slot visibility and action ]]

local game = require("word_game.ui.util.game_runtime").game

local facade = require("word_game.ui.facade")
local InputLock = facade.input_lock()
local Match = facade.match()
local rules = require("word_game.ui.perks.discard_bin.rules")
local counter = require("word_game.ui.perks.discard_bin.counter")

local M = {
	END_RUN_SLOT_SCALE = 0.62,
}

function M.should_show_end_run()
	if not rules.end_run_button_visible() then return false end
	if not rules.voucher_discard_unlocked() then return true end
	return counter.is_full()
end

function M.end_run()
	if rules.voucher_discard_unlocked() and not counter.is_full() then return false end
	if InputLock.is_table_busy() then return false end
	return Match.end_run({ won = false })
end

function M.end_run_slot_size(card_w, card_h)
	card_w = card_w or game().CARD_W or 1
	card_h = card_h or game().CARD_H or 1.4
	local side = math.min(card_w, card_h) * M.END_RUN_SLOT_SCALE
	return side, side
end

return M
