--[[ word_game/ui/trade/layout.lua - marketplace modal geometry ]]

local Layout = require("word_game.ui.layout")

local M = {}

--- Vertical offset (tiles) centreing the modal on the play-area felt.
function M.modal_offset_y()
	local felt = Layout.felt_rect and Layout.felt_rect()
	if not felt or not G.TILE_H then return 0 end
	return (felt.y + felt.h * 0.5) - G.TILE_H * 0.5 - 20 / (G.TILESIZE or 64)
end

--- Modal height (tiles) spans the play-area felt, top to bottom.
function M.modal_minh()
	local felt = Layout.felt_rect and Layout.felt_rect()
	return felt and felt.h or 1
end

function M.room_translate()
	local room = G and G.ROOM
	if not room or not love or not love.graphics then return end
	local ts = (G.TILESCALE or 1) * (G.TILESIZE or 1)
	love.graphics.translate(room.T.w * ts * 0.5, room.T.h * ts * 0.5)
	love.graphics.rotate(room.T.r or 0)
	love.graphics.translate(
		-room.T.w * ts * 0.5 + (room.T.x or 0) * ts,
		-room.T.h * ts * 0.5 + (room.T.y or 0) * ts
	)
end

return M
