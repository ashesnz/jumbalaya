--[[ word_game/ui/sidebar/hud_layout.lua - Sidebar HUD row geometry ]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local felt = require("word_game.ui.layout.felt")
local TableDeck = require("word_game.ui.table.deck")
local stamp_grid = require("word_game.ui.perks.stamp.grid")
local table_discard = require("word_game.ui.perks.discard_bin")

local M = {}

M.SIDEBAR_ROOT_PAD = 0
M.SIDEBAR_FILL_PAD = 0.06
M.SIDEBAR_BOTTOM_PAD = 0.22
M.SIDEBAR_COUNTER_SCALE = 0.38
M.SIDEBAR_COUNTER_ROW_H = 0.35

local function box_width()
	return felt.sidebar_width()
end

local function sidebar_height()
	local sidebar_w = felt.sidebar_width()
	local ts = (runtime().TILESIZE or 1) * (runtime().TILESCALE or 1)
	local win_h = (love and love.graphics and love.graphics.getHeight and love.graphics.getHeight() or 0) / ts
	local room_y = (runtime().ROOM and runtime().ROOM.T and runtime().ROOM.T.y) or 0
	if win_h <= 0 then
		win_h = (runtime().TILE_H or 11.5) + 2 * ((runtime().ROOM_PADDING_H or 0.7))
	end
	return math.max(6, win_h)
end

local function deck_slot_size()
	local scale = TableDeck.SIZE or 0.78
	return TableDeck.footprint(runtime().CARD_W * scale, runtime().CARD_H * scale)
end

local function end_run_slot_size()
	return table_discard.end_run_slot_size(runtime().CARD_W, runtime().CARD_H)
end

function M.stamp_slot_height()
	local count = 1
	if WORD_GAME_UI and WORD_GAME_UI.PerkStamp and WORD_GAME_UI.PerkStamp.stack_count then
		count = WORD_GAME_UI.PerkStamp.stack_count()
	end
	return stamp_grid.panel_height_tiles(count)
end

function M.sidebar_fixed_content_height()
	local _, deck_h = deck_slot_size()
	local _, end_run_h = end_run_slot_size()
	local rows = M.stamp_slot_height()
		+ deck_h
		+ M.SIDEBAR_COUNTER_ROW_H
		+ end_run_h
		+ M.SIDEBAR_BOTTOM_PAD
	local fill_nodes = 6
	local fill_pad = M.SIDEBAR_FILL_PAD * (fill_nodes + 1)
	return M.SIDEBAR_ROOT_PAD * 2 + fill_pad + rows
end

function M.sidebar_spacer_height(sidebar_h)
	sidebar_h = sidebar_h or sidebar_height()
	return math.max(0, sidebar_h - M.sidebar_fixed_content_height())
end

function M.compute()
	local sidebar_h = sidebar_height()
	local box_w = box_width()
	local inner_h = math.max(4, sidebar_h - M.SIDEBAR_ROOT_PAD * 2)
	local stamp_h = M.stamp_slot_height()
	local spacer_h = M.sidebar_spacer_height(sidebar_h)
	local deck_w, deck_h = deck_slot_size()
	local end_w, end_h = end_run_slot_size()
	local end_side = math.min(end_w, end_h)
	local y = M.SIDEBAR_ROOT_PAD + M.SIDEBAR_FILL_PAD

	local stamp_slot = {
		id = "row_stamp_slot",
		x = 0,
		y = y,
		w = box_w,
		h = stamp_h,
	}
	y = y + stamp_h + M.SIDEBAR_FILL_PAD

	local spacer = {
		id = "row_sidebar_spacer",
		x = 0,
		y = y,
		w = box_w,
		h = spacer_h,
	}
	y = y + spacer_h + M.SIDEBAR_FILL_PAD

	local deck = {
		id = "row_deck",
		x = math.max(0, (box_w - deck_w) * 0.5),
		y = y,
		w = deck_w,
		h = deck_h,
	}
	y = y + deck_h + M.SIDEBAR_FILL_PAD

	local deck_count = {
		id = "row_deck_count",
		x = 0,
		y = y,
		w = box_w,
		h = M.SIDEBAR_COUNTER_ROW_H,
	}
	y = y + M.SIDEBAR_COUNTER_ROW_H + M.SIDEBAR_FILL_PAD

	local end_run = {
		id = "row_end_run",
		x = math.max(0, (box_w - end_side) * 0.5),
		y = y,
		w = end_side,
		h = end_side,
	}
	y = y + end_side + M.SIDEBAR_FILL_PAD

	local end_button = {
		id = "end_run_button",
		x = end_run.x,
		y = end_run.y,
		w = end_side,
		h = end_side,
	}

	return {
		panel = { x = 0, y = 0, w = box_w, h = sidebar_h },
		inner = { x = 0, y = M.SIDEBAR_ROOT_PAD, w = box_w, h = inner_h },
		stamp_slot = stamp_slot,
		spacer = spacer,
		deck = deck,
		deck_count = deck_count,
		end_run = end_run,
		end_button = end_button,
		bottom_pad = {
			id = "row_sidebar_bottom_pad",
			x = 0,
			y = y,
			w = box_w,
			h = M.SIDEBAR_BOTTOM_PAD,
		},
	}
end

function M.slot_rect(layout, row_id)
	if not layout then return nil end
	if row_id == "row_stamp_slot" then return layout.stamp_slot end
	if row_id == "row_sidebar_spacer" then return layout.spacer end
	if row_id == "row_deck" then return layout.deck end
	if row_id == "row_deck_count" then return layout.deck_count end
	if row_id == "row_end_run" or row_id == "end_run_button" then return layout.end_button end
	if row_id == "row_sidebar_bottom_pad" then return layout.bottom_pad end
	return nil
end

function M.end_run_button_visible()
	return table_discard.end_run_button_visible()
end

return M
