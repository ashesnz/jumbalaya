--[[ word_game/ui/trade/layout.lua - Marketplace image size (Marketplace.png aspect) ]]

local game = require("word_game.ui.util.game_runtime").game

local M = {}

local ART_W, ART_H = 1408, 768

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

--- Image size in tiles: fitted to most of the game room (full window playfield).
function M.modal_frame()
	local room = game().ROOM and game().ROOM.T
	if not room then
		local w = 12
		return { w = w, h = w / M.art_aspect() }
	end
	local aspect = M.art_aspect()
	local max_w = room.w * 0.97
	local max_h = room.h * 0.94
	local w = max_w
	local h = w / aspect
	if h > max_h then
		h = max_h
		w = h * aspect
	end
	return { w = w, h = h }
end

return M
