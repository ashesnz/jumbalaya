--[[
	word_game/ui/perks/discard_bin/init.lua - Voucher discard in the sidebar stamp slot.

	Discard unlocks with the first perk. Drag hand cards onto the discard_bin
	voucher imprint; the counter overlays the voucher art.
]]

local facade = require("word_game.ui.facade")
local felt = require("word_game.ui.layout.felt")
local round_config = require("word_game.config.gameplay.round")
local game_access = require("word_game.model.game_access")
local Odometer = require("word_game.ui.widgets.odometer")
local perk_voucher = require("word_game.ui.perks.shared.voucher")

local InputLock = facade.input_lock()
local Match = facade.match()
local run_state = facade.run_state()

local hud_definition
local stamp_layout
local stamp_draw

local function stamp_modules()
	if not stamp_layout then
		stamp_layout = require("word_game.ui.perks.stamp.layout")
		stamp_draw = require("word_game.ui.perks.stamp.draw")
	end
	return stamp_layout, stamp_draw
end

local M = {
	END_RUN_SLOT_SCALE = 0.62,
	COUNTER_HEIGHT_FRAC = 0.52,
	COUNTER_X_FRAC = 0.78,
	COUNTER_COLOUR = { 0.08, 0.10, 0.14, 1 },
	DISCARD_PERK_ID = "discard_bin",
}

local discards_used_count = 0
local overlay_odometer

local function tile_scale()
	return (G.TILESCALE or 1) * (G.TILESIZE or 1)
end

local function perk_stamp()
	return WORD_GAME_UI.PerkStamp
end

local function perk_stamp_imprint_count()
	local stamp = perk_stamp()
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

local function ensure_overlay_odometer()
	if overlay_odometer then return overlay_odometer end
	overlay_odometer = Odometer({
		label = "",
		text_shadow = true,
		value = M.discards_left(),
		value_fn = function() return M.discards_left() end,
		colour = M.COUNTER_COLOUR,
	})
	return overlay_odometer
end

function M.overlay_odometer()
	if not M.voucher_discard_unlocked() then return nil end
	return ensure_overlay_odometer()
end

function M.on_unlock()
	M.reset()
	ensure_overlay_odometer()
	M.sync_sidebar_ui()
end

local function read_discards_used()
	local game = game_access.get()
	if game and game.voucher_discards_used ~= nil then
		discards_used_count = game.voucher_discards_used
	elseif game and game.discard_bin_count ~= nil then
		-- Legacy save field from the old bin UI.
		discards_used_count = game.discard_bin_count
	end
	return discards_used_count
end

local function write_discards_used(count)
	discards_used_count = math.max(0, count or 0)
	game_access.patch({
		voucher_discards_used = discards_used_count,
		discard_bin_count = discards_used_count,
	})
end

function M.reset()
	write_discards_used(0)
	overlay_odometer = nil
	M.sync_voucher_counter(true)
end

function M.discards_used()
	return read_discards_used()
end

function M.discards_left()
	return math.max(0, M.max_fills() - read_discards_used())
end

function M.sync_voucher_counter(force)
	local left = M.discards_left()
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
		M.sync_voucher_counter(true)
	end
end

function M.is_full()
	return read_discards_used() >= M.max_fills()
end

function M.uses_table_draw()
	if G.STATE ~= G.STATES.TABLE_BOARD then return false end
	if felt.is_boss_sequence() then return false end
	return true
end

function M.voucher_discard_active()
	return M.voucher_discard_unlocked() and M.uses_table_draw() and M.discards_left() > 0
end

function M.end_run_button_visible()
	if G.STAGE ~= G.STAGES.RUN then return false end
	if felt.is_boss_sequence() then return false end
	return G.STATE == G.STATES.TABLE_BOARD
end

function M.should_show_end_run()
	if not M.end_run_button_visible() then return false end
	if not M.voucher_discard_unlocked() then return true end
	return M.is_full()
end

function M.sync_discard_pile_area()
	if not G.recycle_stash or not G.recycle_stash.states then return end
	G.recycle_stash.states.collide.can = false
	G.recycle_stash.states.hover.can = false
	G.recycle_stash.states.release_on.can = false
end

function M.stash_discarded_card(card)
	if not card or card.played_pool then return end
	card.discard_stash = true
	if card.states then
		card.states.visible = false
	end
end

function M.hide_discard_pile_cards()
	if not G.recycle_stash or not G.recycle_stash.cards then return end
	for _, card in ipairs(G.recycle_stash.cards) do
		M.stash_discarded_card(card)
	end
end

function M.bind_hud_definition(hud)
	hud_definition = hud
end

function M.sync_sidebar_ui()
	M.hide_discard_pile_cards()
	M.sync_voucher_counter()
	M.sync_discard_pile_area()
	if hud_definition and hud_definition.sync_end_run_row then
		hud_definition.sync_end_run_row()
	end
end

function M.end_run()
	if M.voucher_discard_unlocked() and not M.is_full() then return false end
	if InputLock.is_table_busy() then return false end
	return Match.end_run({ won = false })
end

function M.record_discard()
	local used = read_discards_used()
	if used >= M.max_fills() then return false end
	local from_left = M.discards_left()
	write_discards_used(used + 1)
	M.roll_discards_left(from_left, M.discards_left())
	return true
end

function M.end_run_slot_size(card_w, card_h)
	card_w = card_w or G.CARD_W or 1
	card_h = card_h or G.CARD_H or 1.4
	local side = math.min(card_w, card_h) * M.END_RUN_SLOT_SCALE
	return side, side
end

local function discard_voucher_slot_px()
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
			return entry, rect
		end
	end
	return nil
end

local function discard_voucher_rect_px()
	local _, rect = discard_voucher_slot_px()
	return rect
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
	if not card or card.REMOVED or card.area ~= G.dealt_letters then return false end
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

local function voucher_art_rect(perk_entry, slot_x, slot_y, slot_w, slot_h)
	local _, _, pw, ph = perk_voucher.stamp_quad(perk_entry)
	if not pw or not ph then
		return slot_x, slot_y, slot_w, slot_h
	end
	local ox, oy, aw, ah = perk_voucher.fit_rect(pw, ph, slot_w, slot_h)
	return slot_x + ox, slot_y + oy, aw, ah
end

function M.resolve_voucher_perk(imprint_entry)
	if not imprint_entry then return nil end
	if imprint_entry.id == M.DISCARD_PERK_ID then return imprint_entry end
	if imprint_entry.perk and imprint_entry.perk.id == M.DISCARD_PERK_ID then
		return imprint_entry.perk
	end
	return nil
end

function M.voucher_counter_layout(imprint_entry, slot_x, slot_y, slot_w, slot_h)
	local perk_entry = M.resolve_voucher_perk(imprint_entry)
	if not perk_entry then return nil end
	if not M.voucher_discard_unlocked() or not M.uses_table_draw() then return nil end
	local left = M.discards_left()

	local art_x, art_y, art_w, art_h = voucher_art_rect(perk_entry, slot_x, slot_y, slot_w, slot_h)
	return {
		perk = perk_entry,
		art_x = art_x,
		art_y = art_y,
		art_w = art_w,
		art_h = art_h,
		cx = art_x + art_w * M.COUNTER_X_FRAC,
		cy = art_y + art_h * 0.5,
		height = art_h * M.COUNTER_HEIGHT_FRAC,
		value = left,
	}
end

function M.visible_counter_digit()
	local odometer = M.overlay_odometer()
	if not odometer then return nil end
	if odometer.roll then
		return tostring(odometer.roll.from)
	end
	return tostring(odometer.display_count or odometer:current_value())
end

local function voucher_hover_highlight(art_x, art_y, art_w, art_h)
	local dragging = G.INPUT and G.INPUT.dragging and G.INPUT.dragging.target
	if not dragging or not M.can_discard_card(dragging) then return false end
	return M.point_in_discard_voucher(
		dragging.T.x + dragging.T.w * 0.5,
		dragging.T.y + dragging.T.h * 0.5
	)
end

local function draw_yellow_halo(x, y, w, h)
	local r = math.min(8, w * 0.09, h * 0.14)
	love.graphics.setLineJoin("bevel")
	for layer = 3, 1, -1 do
		local spread = layer * 2.2
		local alpha = 0.12 + (3 - layer) * 0.14
		love.graphics.setColor(1, 0.92, 0.18, alpha)
		love.graphics.setLineWidth(1.5 + layer * 1.8)
		love.graphics.rectangle(
			"line",
			x - spread, y - spread,
			w + spread * 2, h + spread * 2,
			r + spread, r + spread
		)
	end
	love.graphics.setColor(1, 1, 0.62, 0.95)
	love.graphics.setLineWidth(2.2)
	love.graphics.rectangle("line", x, y, w, h, r, r)
	love.graphics.setLineWidth(1)
end

function M.draw_voucher_overlay(imprint_entry, x, y, w, h)
	local layout = M.voucher_counter_layout(imprint_entry, x, y, w, h)
	if not layout then return end

	if voucher_hover_highlight(layout.art_x, layout.art_y, layout.art_w, layout.art_h) then
		draw_yellow_halo(layout.art_x, layout.art_y, layout.art_w, layout.art_h)
	end

	local odometer = M.overlay_odometer()
	if odometer and odometer.draw_rolling_px then
		odometer:draw_rolling_px(layout.cx, layout.cy, layout.height)
	end

	love.graphics.setColor(1, 1, 1, 1)
end

--- Redraw the discard_bin voucher and counter above dragged/dissolving cards.
function M.draw_voucher_foreground()
	if not M.voucher_discard_unlocked() or not M.uses_table_draw() then return end
	if G.STATE ~= G.STATES.TABLE_BOARD or not G.ROOM or not love.graphics then return end

	local entry, rect = discard_voucher_slot_px()
	if not entry or not rect then return end

	local layout_mod, draw_mod = stamp_modules()
	local prev_shader = love.graphics.getShader()
	local cr, cg, cb, ca = love.graphics.getColor()

	love.graphics.push()
	love.graphics.setShader()
	layout_mod.room_translate()
	draw_mod.draw_type_imprint(entry.perk or entry.sprite, rect.x, rect.y, rect.w, rect.h, 1)
	M.draw_voucher_overlay(entry, rect.x, rect.y, rect.w, rect.h)
	love.graphics.pop()

	if prev_shader then love.graphics.setShader(prev_shader) end
	love.graphics.setColor(cr, cg, cb, ca)
end

return M
