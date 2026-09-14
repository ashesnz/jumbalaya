--[[ word_game/ui/table/token_reward/layout.lua - Fly path geometry and sticker quad ]]

local GameRT = require("word_game.ui.util.game_runtime")
local Layout = require("word_game.ui.layout")
local config = require("word_game.ui.table.token_reward.config")

local M = {}

local function runtime()
	return GameRT.game()
end

function M.room_translate()
	local room = runtime() and runtime().ROOM
	if not room or not love or not love.graphics then return end
	local ts = (runtime().TILESCALE or 1) * (runtime().TILESIZE or 1)
	love.graphics.translate(room.T.w * ts * 0.5, room.T.h * ts * 0.5)
	love.graphics.rotate(room.T.r or 0)
	love.graphics.translate(
		-room.T.w * ts * 0.5 + (room.T.x or 0) * ts,
		-room.T.h * ts * 0.5 + (room.T.y or 0) * ts
	)
end

function M.timeline_center_px()
	local ts = (runtime().TILESCALE or 1) * (runtime().TILESIZE or 1)
	local rect = Layout.timeline_rect()
	local w = rect.w * ts
	local h = rect.h * ts
	local slant = (rect.slant or (rect.h * 0.88)) * ts
	local x = rect.x * ts
	local y = rect.y * ts
	return x + (w - slant * 0.5) * 0.5, y + h * 0.5
end

function M.resolve_target_px()
	if runtime().draw_pile and WORD_GAME_UI.TableDeck and WORD_GAME_UI.TableDeck.token_center_px then
		local cx, cy = WORD_GAME_UI.TableDeck.token_center_px(runtime().draw_pile)
		if cx and cy then return cx, cy end
	end
	local deck = Layout.deck_rect()
	local ts = (runtime().TILESCALE or 1) * (runtime().TILESIZE or 1)
	return (deck.x + deck.w * 0.5) * ts, deck.y * ts
end

function M.sticker_quad()
	local atlas = runtime().TEXTURE_ATLASES and runtime().TEXTURE_ATLASES.coin
	if not atlas or not atlas.image then return end
	local iw, ih = atlas.image:getDimensions()
	local px, py = atlas.px or iw, atlas.py or ih
	local qx = config.STICKER_CELL.x * px
	local qy = config.STICKER_CELL.y * py
	return atlas.image, love.graphics.newQuad(qx, qy, px, py, iw, ih), px, py
end

return M
