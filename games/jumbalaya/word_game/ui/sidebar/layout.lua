--[[
	word_game/ui/sidebar/layout.lua - Sidebar column and draw-pile geometry.
]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local felt = require("word_game.ui.layout.felt")
local TableDeck = require("word_game.ui.table.deck")
local voucher_discard = require("word_game.ui.perks.discard_bin")

local M = {}

function M.sidebar_edge()
	return math.max(0.22, runtime().TILE_H * felt.SIDEBAR_EDGE_FRAC)
end

function M.sidebar_bottom_edge()
	return math.max(0.55, runtime().TILE_H * felt.SIDEBAR_BOTTOM_FRAC)
end

function M.sidebar_rect()
	local sidebar_w = felt.sidebar_width()
	local ts = (runtime().TILESIZE or 1) * (runtime().TILESCALE or 1)
	local win_h = (love and love.graphics and love.graphics.getHeight and love.graphics.getHeight() or 0) / ts
	local room_y = (runtime().ROOM and runtime().ROOM.T and runtime().ROOM.T.y) or 0
	if win_h <= 0 then
		win_h = (runtime().TILE_H or 11.5) + 2 * ((runtime().ROOM_PADDING_H or 0.7))
	end
	return {
		x = felt.sidebar_right_x() - sidebar_w,
		y = -room_y,
		w = sidebar_w,
		h = math.max(6, win_h),
	}
end

function M.sidebar_height()
	return M.sidebar_rect().h
end

function M.sidebar_left()
	if runtime().ROOM then return M.sidebar_rect().x end
	return (runtime().TILE_W or 20) - (felt.sidebar_width and felt.sidebar_width() or 3.0)
end

function M.deck_slot_size()
	local scale = TableDeck.SIZE or 0.78
	return TableDeck.footprint(runtime().CARD_W * scale, runtime().CARD_H * scale)
end

function M.end_run_slot_size()
	return voucher_discard.end_run_slot_size(runtime().CARD_W, runtime().CARD_H)
end

local function layout_rows()
	local views_install = require("word_game.ui.views.install")
	local view = views_install.sidebar_view()
	if view and view.layout then
		return view:layout()
	end
	return require("word_game.ui.sidebar.hud_layout").compute()
end

local function slot_rect(row_id, w, h)
	local layout = layout_rows()
	local rect = require("word_game.ui.sidebar.hud_layout").slot_rect(layout, row_id)
	if rect then
		return {
			x = rect.x + math.max(0, ((rect.w or w) - w) * 0.5),
			y = rect.y + math.max(0, ((rect.h or h) - h) * 0.5),
			w = w,
			h = h,
		}
	end
	return nil
end

function M.end_run_rect()
	local w, h = M.end_run_slot_size()
	local rect = slot_rect("row_end_run", w, h)
	if rect then return rect end
	local deck = M.deck_rect()
	return {
		x = deck.x + math.max(0, (deck.w - w) * 0.5),
		y = deck.y + deck.h + 0.08,
		w = w,
		h = h,
	}
end

function M.deck_rect()
	local w, h = M.deck_slot_size()
	local rect = slot_rect("row_deck", w, h)
	if rect then return rect end

	local panel = felt.panel_rect()
	local col_x, col_w = panel.x, panel.w
	return {
		x = col_x + math.max(0, (col_w - w) * 0.5),
		y = runtime().TILE_H - h - 0.22,
		w = w,
		h = h,
	}
end

function M.update_sidebar_attach()
	if not runtime().SIDEBAR_ATTACH then return end
	local sidebar = M.sidebar_rect()
	runtime().SIDEBAR_ATTACH.T.x = sidebar.x
	runtime().SIDEBAR_ATTACH.T.y = sidebar.y
	runtime().SIDEBAR_ATTACH.T.w = sidebar.w
	runtime().SIDEBAR_ATTACH.T.h = sidebar.h
	if runtime().SIDEBAR_ATTACH.hard_set_T then
		runtime().SIDEBAR_ATTACH:hard_set_T(sidebar.x, sidebar.y, sidebar.w, sidebar.h)
	end
end

function M.update_panel_attach()
	if not runtime().PANEL_ATTACH then return end
	local panel = felt.panel_rect()
	runtime().PANEL_ATTACH.T.x = panel.x
	runtime().PANEL_ATTACH.T.y = panel.y
	runtime().PANEL_ATTACH.T.w = panel.w
	runtime().PANEL_ATTACH.T.h = panel.h
	runtime().PANEL_ATTACH:hard_set_T(panel.x, panel.y, panel.w, panel.h)
end

return M
