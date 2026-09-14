--[[ word_game/ui/perks/discard_bin/input.lua - Drag-to-discard hit testing and deck dispatch ]]

local game = require("word_game.ui.util.game_runtime").game

local facade = require("word_game.ui.facade")
local shell = facade.shell()
local InputLock = facade.input_lock()
local Deck = facade.deck()
local rules = require("word_game.ui.perks.discard_bin.rules")
local counter = require("word_game.ui.perks.discard_bin.counter")

local M = {}

local function tile_scale()
	return (game().TILESCALE or 1) * (game().TILESIZE or 1)
end

local function discard_voucher_slot_px()
	local stamp = WORD_GAME_UI and WORD_GAME_UI.PerkStamp
	if not stamp or not stamp.imprint_cell_rects_px or not stamp.current_imprints then
		return nil
	end
	local imprints = stamp.current_imprints()
	local rects = stamp.imprint_cell_rects_px()
	for i, rect in ipairs(rects) do
		local entry = imprints[i]
		local perk = entry and entry.perk
		if perk and perk.id == rules.DISCARD_PERK_ID then
			return entry, rect
		end
	end
	return nil
end

local function discard_voucher_rect_px()
	local _, rect = discard_voucher_slot_px()
	return rect
end

function M.voucher_discard_active()
	return rules.voucher_discard_unlocked()
		and rules.uses_table_draw()
		and counter.discards_left() > 0
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
	if not card or card.REMOVED or card.area ~= shell.dealt_letters() then return false end
	if card.bonus_card or card.boss_temp then return false end
	if InputLock.is_table_busy() then return false end
	return true
end

function M.try_discard(card)
	if not M.can_discard_card(card) then return false end
	local cx = card.T.x + card.T.w * 0.5
	local cy = card.T.y + card.T.h * 0.5
	if not M.point_in_discard_voucher(cx, cy) then return false end
	local deck = Deck
	if not deck or not deck.discard_from_hand then return false end
	return deck.discard_from_hand(card)
end

function M.discard_voucher_slot_px()
	return discard_voucher_slot_px()
end

return M
