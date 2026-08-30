--[[
	word_game/ui/layout/vault.lua - Vault column and draw-pile geometry.
]]

local felt = require("word_game.ui.layout.felt")

local M = {}

function M.vault_edge()
	return math.max(0.22, G.TILE_H * felt.VAULT_EDGE_FRAC)
end

function M.vault_bottom_edge()
	return math.max(0.55, G.TILE_H * felt.VAULT_BOTTOM_FRAC)
end

function M.vault_rect()
	local sidebar_w = felt.sidebar_width()
	local ts = (G.TILESIZE or 1) * (G.TILESCALE or 1)
	local win_h = (love and love.graphics and love.graphics.getHeight and love.graphics.getHeight() or 0) / ts
	local room_y = (G.ROOM and G.ROOM.T and G.ROOM.T.y) or 0
	if win_h <= 0 then
		win_h = (G.TILE_H or 11.5) + 2 * ((G.ROOM_PADDING_H or 0.7))
	end
	local top = M.vault_edge()
	local bottom = M.vault_bottom_edge()
	return {
		x = felt.vault_right_x() - sidebar_w,
		y = -room_y + top,
		w = sidebar_w,
		h = math.max(6, win_h - top - bottom),
	}
end

function M.vault_height()
	return M.vault_rect().h
end

function M.vault_left()
	local hud = G.VAULT_HUD
	if not hud then
		if G.ROOM then return M.vault_rect().x end
		return (G.TILE_W or 20) - (felt.sidebar_width and felt.sidebar_width() or 3.0)
	end
	if not (hud.T and (hud.T.x or 0) > 0) then return M.vault_rect().x end
	local room = G.ROOM and G.ROOM.T
	if not room then return (G.TILE_W or 20) - (felt.sidebar_width and felt.sidebar_width() or 3.0) end
	return M.vault_rect().x
end

function M.deck_slot_size()
	local TableDeck = require("word_game.ui.table_deck")
	local scale = TableDeck.SIZE or 0.78
	return TableDeck.footprint(G.CARD_W * scale, G.CARD_H * scale)
end

function M.discard_slot_size()
	local TableDiscard = require("word_game.ui.table_discard")
	return TableDiscard.footprint(G.CARD_W, G.CARD_H)
end

function M.deck_rect()
	local w, h = M.deck_slot_size()
	local row = G.VAULT_HUD and G.VAULT_HUD:find_node_by_id("row_deck")
	if row and row.T then
		return {
			x = row.T.x + math.max(0, ((row.T.w or w) - w) * 0.5),
			y = row.T.y + math.max(0, ((row.T.h or h) - h) * 0.5),
			w = w,
			h = h,
		}
	end

	local hud = G.VAULT_HUD
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

function M.discard_rect()
	local w, h = M.discard_slot_size()
	local row = G.VAULT_HUD and G.VAULT_HUD:find_node_by_id("row_discard")
	if row and row.T then
		return {
			x = row.T.x + math.max(0, ((row.T.w or w) - w) * 0.5),
			y = row.T.y + math.max(0, ((row.T.h or h) - h) * 0.5),
			w = w,
			h = h,
		}
	end
	local deck = M.deck_rect()
	return {
		x = deck.x + math.max(0, (deck.w - w) * 0.5),
		y = deck.y + deck.h + 0.08,
		w = w,
		h = h,
	}
end

function M.update_vault_attach()
	if not G.VAULT_ATTACH then return end
	local vault = M.vault_rect()
	G.VAULT_ATTACH.T.x = vault.x
	G.VAULT_ATTACH.T.y = vault.y
	G.VAULT_ATTACH.T.w = vault.w
	G.VAULT_ATTACH.T.h = vault.h
	if G.VAULT_ATTACH.hard_set_T then
		G.VAULT_ATTACH:hard_set_T(vault.x, vault.y, vault.w, vault.h)
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
