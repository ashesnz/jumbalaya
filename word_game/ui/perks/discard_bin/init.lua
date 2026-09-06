--[[
	word_game/ui/perks/discard_bin/init.lua - Voucher discard in the vault stamp slot.

	Discard is enabled once a perk is collected. Drag hand cards onto the
	discard_bin perk voucher; the counter overlays the voucher (not a bin icon).
]]

local felt = require("word_game.ui.layout.felt")
local round_config = require("word_game.config.round_config")
local InputLock = require("word_game.model.input_lock")
local Match = require("word_game.model.match")
local Odometer = require("word_game.ui.odometer")
local run_state = require("word_game.model.state")

local M = {
	END_RUN_SLOT_SCALE = 0.62,
	COUNTER_TEXT_SCALE = 0.38,
	DISCARD_PERK_ID = "discard_bin",
}

local fill_count = 0
local overlay_odometer

local function tile_scale()
	return (G.TILESCALE or 1) * (G.TILESIZE or 1)
end

local function perk_stamp()
	return WORD_GAME and WORD_GAME.PerkStamp
end

local function perk_stamp_imprint_count()
	local stamp = perk_stamp()
	if stamp and stamp.imprint_count then
		return stamp.imprint_count()
	end
	return 0
end

function M.bin_enabled()
	local rs = run_state.get()
	if rs and #(rs.perks or {}) >= 1 then
		return true
	end
	return perk_stamp_imprint_count() >= 1
end

function M.max_fills()
	if M.bin_enabled() then
		return round_config.BIN_DISCARDS_PER_HAND
	end
	return round_config.DISCARDS_PER_HAND
end

local function ensure_overlay_odometer()
	if overlay_odometer then return overlay_odometer end
	overlay_odometer = Odometer({
		label = "",
		text_scale = M.COUNTER_TEXT_SCALE,
		text_shadow = true,
		value = M.discards_left(),
		value_fn = function() return M.discards_left() end,
		colour = G.C.UI.TEXT_LIGHT,
	})
	return overlay_odometer
end

function M.overlay_odometer()
	if not M.bin_enabled() then return nil end
	return ensure_overlay_odometer()
end

function M.on_unlock()
	M.reset()
	ensure_overlay_odometer()
	M.sync_vault_ui()
end

local function read_count()
	if G.GAME and G.GAME.discard_bin_count ~= nil then
		fill_count = G.GAME.discard_bin_count
	end
	return fill_count
end

local function write_count(count)
	fill_count = math.max(0, count or 0)
	if G.GAME then
		G.GAME.discard_bin_count = fill_count
	end
end

function M.reset()
	write_count(0)
	overlay_odometer = nil
	M.sync_discards_left_display(true)
end

function M.fill_count()
	return read_count()
end

function M.discards_left()
	return math.max(0, M.max_fills() - read_count())
end

function M.sync_discards_left_display(force)
	local left = M.discards_left()
	G.ARGS = G.ARGS or {}
	G.ARGS.discards_left_count = left
	local odometer = M.overlay_odometer()
	if not odometer then return end
	if force or not odometer.roll then
		odometer.display_count = left
	end
end

function M.roll_discards_left(from_left, to_left)
	local odometer = M.overlay_odometer()
	if odometer and odometer.start_roll then
		odometer:start_roll(from_left, to_left)
	else
		M.sync_discards_left_display(true)
	end
end

function M.is_full()
	return read_count() >= M.max_fills()
end

function M.uses_table_draw()
	if G.STATE ~= G.STATES.TABLE_BOARD then return false end
	if felt.is_boss_sequence() then return false end
	return true
end

function M.voucher_discard_active()
	return M.bin_enabled() and M.uses_table_draw() and M.discards_left() > 0
end

function M.end_run_button_visible()
	if G.STAGE ~= G.STAGES.RUN then return false end
	if felt.is_boss_sequence() then return false end
	return G.STATE == G.STATES.TABLE_BOARD
end

function M.should_show_end_run()
	if not M.end_run_button_visible() then return false end
	if not M.bin_enabled() then return true end
	return M.is_full()
end

function M.sync_discard_area()
	if not G.discard or not G.discard.states then return end
	G.discard.states.collide.can = false
	G.discard.states.hover.can = false
	G.discard.states.release_on.can = false
end

function M.stash_bin_card(card)
	if not card or card.played_pool then return end
	card.bin_stash = true
	if card.states then
		card.states.visible = false
	end
end

function M.hide_bin_cards()
	if not G.discard or not G.discard.cards then return end
	for _, card in ipairs(G.discard.cards) do
		M.stash_bin_card(card)
	end
end

function M.is_pile_card_visible(card, discard_area)
	if not card or not discard_area then return false end
	if card.played_pool or card.bin_stash then return false end
	if card.states and card.states.visible == false then return false end
	return false
end

function M.sync_vault_ui()
	M.hide_bin_cards()
	M.sync_discards_left_display()
	M.sync_discard_area()
	local hud = require("word_game.ui.sidebar.hud_definition")
	if hud.sync_discard_row then
		hud.sync_discard_row()
	end
end

function M.end_run()
	if M.bin_enabled() and not M.is_full() then return false end
	if InputLock.is_table_busy() then return false end
	return Match.end_run({ won = false })
end

function M.record_discard()
	local count = read_count()
	if count >= M.max_fills() then return false end
	local from_left = M.discards_left()
	write_count(count + 1)
	M.roll_discards_left(from_left, M.discards_left())
	return true
end

function M.end_run_slot_size(card_w, card_h)
	card_w = card_w or G.CARD_W or 1
	card_h = card_h or G.CARD_H or 1.4
	local side = math.min(card_w, card_h) * M.END_RUN_SLOT_SCALE
	return side, side
end

--- @deprecated use end_run_slot_size; kept for layout call sites.
function M.footprint(card_w, card_h)
	return M.end_run_slot_size(card_w, card_h)
end

local function discard_voucher_rect_px()
	local stamp = perk_stamp()
	if not stamp or not stamp.imprint_cell_rects_px or not stamp.current_imprints then
		return nil
	end
	local imprints = stamp.current_imprints()
	local rects = stamp.imprint_cell_rects_px()
	for i, rect in ipairs(rects) do
		local entry = imprints[i]
		local perk = entry and entry.perk
		if perk and perk.id == M.DISCARD_PERK_ID then
			return rect
		end
	end
	return nil
end

function M.point_in_discard_voucher(tx, ty)
	if not M.voucher_discard_active() then return false end
	local rect = discard_voucher_rect_px()
	if not rect then return false end
	local ts = tile_scale()
	local sx, sy = tx * ts, ty * ts
	return sx >= rect.x and sx <= rect.x + rect.w and sy >= rect.y and sy <= rect.y + rect.h
end

function M.voucher_discard_center()
	local rect = discard_voucher_rect_px()
	if not rect then return nil end
	local ts = tile_scale()
	return (rect.x + rect.w * 0.5) / ts, (rect.y + rect.h * 0.5) / ts
end

function M.can_discard_card(card)
	if not M.voucher_discard_active() then return false end
	if not card or card.REMOVED or card.area ~= G.hand then return false end
	if card.bonus_card or card.boss_temp then return false end
	if InputLock.is_table_busy() then return false end
	return true
end

function M.try_discard(card)
	if not M.can_discard_card(card) then return false end
	local cx = card.T.x + card.T.w * 0.5
	local cy = card.T.y + card.T.h * 0.5
	if not M.point_in_discard_voucher(cx, cy) then return false end
	local deck = WORD_GAME and WORD_GAME.Deck
	if not deck or not deck.discard_from_hand then return false end
	return deck.discard_from_hand(card)
end

function M.draw_voucher_overlay(perk_entry, x, y, w, h)
	if not perk_entry or perk_entry.id ~= M.DISCARD_PERK_ID then return end
	if not M.bin_enabled() then return end

	local dragging = G.INPUT and G.INPUT.dragging and G.INPUT.dragging.target
	local highlight = dragging
		and M.can_discard_card(dragging)
		and M.point_in_discard_voucher(
			dragging.T.x + dragging.T.w * 0.5,
			dragging.T.y + dragging.T.h * 0.5
		)

	if highlight then
		love.graphics.setColor(1, 1, 0.82, 0.38)
		love.graphics.rectangle("fill", x, y, w, h, 4, 4)
	end

	local left = M.discards_left()
	if left > 0 and M.voucher_discard_active() then
		local odometer = M.overlay_odometer()
		if odometer then
			love.graphics.push()
			love.graphics.translate(x + w + w * 0.04, y + h * 0.32)
			odometer:draw_text_scale()
			love.graphics.pop()
		end
	end

	love.graphics.setColor(1, 1, 1, 1)
end

return M
