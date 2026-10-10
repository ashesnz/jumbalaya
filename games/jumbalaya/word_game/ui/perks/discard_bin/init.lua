--[[
	word_game/ui/perks/discard_bin/init.lua - Discard-bin facade (sidebar stamp slot).

	Submodules: rules, counter, pile, input, draw, end_run.
]]

local rules = require("word_game.ui.perks.discard_bin.rules")
local counter = require("word_game.ui.perks.discard_bin.counter")
local pile = require("word_game.ui.perks.discard_bin.pile")
local input = require("word_game.ui.perks.discard_bin.input")
local draw = require("word_game.ui.perks.discard_bin.draw")
local end_run = require("word_game.ui.perks.discard_bin.end_run")

local M = {
	DISCARD_PERK_ID = rules.DISCARD_PERK_ID,
	END_RUN_SLOT_SCALE = end_run.END_RUN_SLOT_SCALE,
	COUNTER_HEIGHT_FRAC = counter.COUNTER_HEIGHT_FRAC,
	COUNTER_X_FRAC = counter.COUNTER_X_FRAC,
	COUNTER_COLOUR = counter.COUNTER_COLOUR,
}

local hud_definition

M.discard_bin_unlocked = rules.discard_bin_unlocked
M.max_fills = rules.max_fills
M.uses_table_draw = rules.uses_table_draw
M.end_run_button_visible = rules.end_run_button_visible

M.overlay_odometer = counter.overlay_odometer
M.reset = counter.reset
M.discards_used = counter.discards_used
M.discards_left = counter.discards_left
M.sync_discard_counter = counter.sync_discard_counter
M.roll_discards_left = counter.roll_discards_left
M.is_full = counter.is_full
M.record_discard = counter.record_discard

M.sync_discard_pile_area = pile.sync_discard_pile_area
M.hide_discard_pile_cards = pile.hide_discard_pile_cards

M.discard_bin_active = input.discard_bin_active
M.point_in_discard_bin = input.point_in_discard_bin
M.discard_bin_center = input.discard_bin_center
M.can_discard_card = input.can_discard_card
M.try_discard = input.try_discard

M.resolve_discard_perk = draw.resolve_discard_perk
M.discard_counter_layout = draw.discard_counter_layout
M.draw_discard_overlay = draw.draw_discard_overlay
M.draw_discard_foreground = draw.draw_discard_foreground

M.should_show_end_run = end_run.should_show_end_run
M.end_run = end_run.end_run
M.end_run_slot_size = end_run.end_run_slot_size

function M.on_unlock()
	M.reset()
	counter.ensure_odometer()
	M.sync_sidebar_ui()
end

function M.bind_hud_definition(hud)
	hud_definition = hud
end

function M.sync_sidebar_ui()
	M.hide_discard_pile_cards()
	M.sync_discard_counter()
	M.sync_discard_pile_area()
	if hud_definition and hud_definition.sync_end_run_row then
		hud_definition.sync_end_run_row()
	end
end

return M
