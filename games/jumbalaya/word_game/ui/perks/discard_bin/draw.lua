--[[ word_game/ui/perks/discard_bin/draw.lua - Voucher imprint overlay and counter draw ]]

local game = require("word_game.ui.util.game_runtime").game

local perk_voucher = require("word_game.ui.perks.shared.voucher")
local rules = require("word_game.ui.perks.discard_bin.rules")
local counter = require("word_game.ui.perks.discard_bin.counter")
local input = require("word_game.ui.perks.discard_bin.input")

local stamp_layout
local stamp_draw

local function stamp_modules()
	if not stamp_layout then
		stamp_layout = require("word_game.ui.perks.stamp.layout")
		stamp_draw = require("word_game.ui.perks.stamp.draw")
	end
	return stamp_layout, stamp_draw
end

local M = {}

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
	if imprint_entry.id == rules.DISCARD_PERK_ID then return imprint_entry end
	if imprint_entry.perk and imprint_entry.perk.id == rules.DISCARD_PERK_ID then
		return imprint_entry.perk
	end
	return nil
end

function M.voucher_counter_layout(imprint_entry, slot_x, slot_y, slot_w, slot_h)
	local perk_entry = M.resolve_voucher_perk(imprint_entry)
	if not perk_entry then return nil end
	if not rules.voucher_discard_unlocked() or not rules.uses_table_draw() then return nil end
	local left = counter.discards_left()

	local art_x, art_y, art_w, art_h = voucher_art_rect(perk_entry, slot_x, slot_y, slot_w, slot_h)
	return {
		perk = perk_entry,
		art_x = art_x,
		art_y = art_y,
		art_w = art_w,
		art_h = art_h,
		cx = art_x + art_w * counter.COUNTER_X_FRAC,
		cy = art_y + art_h * 0.5,
		height = art_h * counter.COUNTER_HEIGHT_FRAC,
		value = left,
	}
end

local function voucher_hover_highlight(art_x, art_y, art_w, art_h)
	local dragging = game().INPUT and game().INPUT.dragging and game().INPUT.dragging.target
	if not dragging or not input.can_discard_card(dragging) then return false end
	return input.point_in_discard_voucher(
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

	local odometer = counter.overlay_odometer()
	if odometer and odometer.draw_rolling_px then
		odometer:draw_rolling_px(layout.cx, layout.cy, layout.height)
	end

	love.graphics.setColor(1, 1, 1, 1)
end

function M.draw_voucher_foreground()
	if not rules.voucher_discard_unlocked() or not rules.uses_table_draw() then return end
	if game().STATE ~= game().STATES.TABLE_BOARD or not game().ROOM or not love.graphics then return end

	local entry, rect = input.discard_voucher_slot_px()
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
