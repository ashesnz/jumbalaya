--[[
	word_game/ui/sidebar/layout.lua - Sidebar column and draw-pile geometry.
]]

local felt = require("word_game.ui.layout.felt")

local M = {}

function M.sidebar_edge()
	return math.max(0.22, G.TILE_H * felt.SIDEBAR_EDGE_FRAC)
end

function M.sidebar_bottom_edge()
	return math.max(0.55, G.TILE_H * felt.SIDEBAR_BOTTOM_FRAC)
end

function M.sidebar_rect()
	local sidebar_w = felt.sidebar_width()
	local ts = (G.TILESIZE or 1) * (G.TILESCALE or 1)
	local win_h = (love and love.graphics and love.graphics.getHeight and love.graphics.getHeight() or 0) / ts
	local room_y = (G.ROOM and G.ROOM.T and G.ROOM.T.y) or 0
	if win_h <= 0 then
		win_h = (G.TILE_H or 11.5) + 2 * ((G.ROOM_PADDING_H or 0.7))
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
	local hud = G.SIDEBAR_HUD
	if not hud then
		if G.ROOM then return M.sidebar_rect().x end
		return (G.TILE_W or 20) - (felt.sidebar_width and felt.sidebar_width() or 3.0)
	end
	if not (hud.T and (hud.T.x or 0) > 0) then return M.sidebar_rect().x end
	local room = G.ROOM and G.ROOM.T
	if not room then return (G.TILE_W or 20) - (felt.sidebar_width and felt.sidebar_width() or 3.0) end
	return M.sidebar_rect().x
end

function M.deck_slot_size()
	local TableDeck = require("word_game.ui.table.deck")
	local scale = TableDeck.SIZE or 0.78
	return TableDeck.footprint(G.CARD_W * scale, G.CARD_H * scale)
end

function M.end_run_slot_size()
	local voucher_discard = require("word_game.ui.perks.discard_bin")
	return voucher_discard.end_run_slot_size(G.CARD_W, G.CARD_H)
end

local function slot_rect(row_id, w, h)
	local row = G.SIDEBAR_HUD and G.SIDEBAR_HUD:find_node_by_id(row_id)
	if row and row.T then
		return {
			x = row.T.x + math.max(0, ((row.T.w or w) - w) * 0.5),
			y = row.T.y + math.max(0, ((row.T.h or h) - h) * 0.5),
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

	local hud = G.SIDEBAR_HUD
	local col_x, col_w
	if hud and hud.T and (hud.T.w or 0) > 0 then
		col_x, col_w = hud.T.x, hud.T.w
	else
		local panel = felt.panel_rect()
		col_x, col_w = panel.x, panel.w
	end
	return {
		x = col_x + math.max(0, (col_w - w) * 0.5),
		y = G.TILE_H - h - 0.22,
		w = w,
		h = h,
	}
end

function M.update_sidebar_attach()
	if not G.SIDEBAR_ATTACH then return end
	local sidebar = M.sidebar_rect()
	G.SIDEBAR_ATTACH.T.x = sidebar.x
	G.SIDEBAR_ATTACH.T.y = sidebar.y
	G.SIDEBAR_ATTACH.T.w = sidebar.w
	G.SIDEBAR_ATTACH.T.h = sidebar.h
	if G.SIDEBAR_ATTACH.hard_set_T then
		G.SIDEBAR_ATTACH:hard_set_T(sidebar.x, sidebar.y, sidebar.w, sidebar.h)
	end
end

function M.update_panel_attach()
	if not G.PANEL_ATTACH then return end
	local panel = felt.panel_rect()
	G.PANEL_ATTACH.T.x = panel.x
	G.PANEL_ATTACH.T.y = panel.y
	G.PANEL_ATTACH.T.w = panel.w
	G.PANEL_ATTACH.T.h = panel.h
	G.PANEL_ATTACH:hard_set_T(panel.x, panel.y, panel.w, panel.h)
end

return M
