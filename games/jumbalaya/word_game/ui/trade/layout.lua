--[[ word_game/ui/trade/layout.lua - Marketplace image size (Marketplace.png aspect) ]]

local game = require("word_game.ui.util.game_runtime").game

local M = {}

local ART_W, ART_H = 1408, 768
local MODAL_EXTRA_TRIM_PX = 50

local function px_to_tiles(px)
	local g = game()
	local ts = (g.TILESIZE or 20) * (g.TILESCALE or 1)
	return px / ts
end

function M.art_pixel_size()
	local atlas = game().TEXTURE_ATLASES and game().TEXTURE_ATLASES.marketplace_bg
	if atlas and atlas.px and atlas.py then
		return atlas.px, atlas.py
	end
	return ART_W, ART_H
end

function M.art_aspect()
	local w, h = M.art_pixel_size()
	return w / h
end

local function during_table_play()
	local g = game()
	if not g.STAGES or not g.STATES then
		return false
	end
	return g.STAGE == g.STAGES.RUN or g.STATE == g.STATES.TABLE_BOARD
end

local function play_column_width()
	if not during_table_play() then
		return nil
	end
	local felt = require("word_game.ui.layout.felt")
	return felt.play_column().w
end

--- Horizontal shift so the modal centers over the play column, not the full room.
function M.modal_overlay_offset()
	local room = game().ROOM and game().ROOM.T
	if not room then
		return { x = 0, y = 0 }
	end
	if not during_table_play() then
		return { x = 0, y = 0 }
	end
	local felt = require("word_game.ui.layout.felt")
	local play = felt.play_column()
	local room_center_x = room.x + room.w * 0.5
	local play_center_x = play.x + play.w * 0.5
	return { x = play_center_x - room_center_x, y = 0 }
end

--- Image size in tiles: fit playfield width (leave sidebar exposed) minus a small trim.
function M.modal_frame()
	local room = game().ROOM and game().ROOM.T
	if not room then
		local w = 12
		return { w = w, h = w / M.art_aspect() }
	end
	local aspect = M.art_aspect()
	local trim = px_to_tiles(MODAL_EXTRA_TRIM_PX)
	local max_w = room.w * 0.97
	local play_w = play_column_width()
	if play_w then
		max_w = math.min(max_w, play_w - trim)
	else
		max_w = max_w - trim
	end
	max_w = math.max(max_w, 6)
	local max_h = room.h * 0.94
	local w = max_w
	local h = w / aspect
	if h > max_h then
		h = max_h
		w = h * aspect
	end
	return { w = w, h = h }
end

M.MODAL_EXTRA_TRIM_PX = MODAL_EXTRA_TRIM_PX

return M
