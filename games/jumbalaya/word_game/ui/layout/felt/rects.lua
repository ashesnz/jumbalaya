--[[ word_game/ui/layout/felt/rects.lua - Play column and felt rectangles ]]

local game = require("word_game.ui.util.game_runtime").game
local config = require("word_game.ui.layout.felt.config")
local sidebar = require("word_game.ui.layout.felt.sidebar")
local hud = require("word_game.ui.layout.felt.hud")

local M = {}


function M.hand_play_column()
	local pad_x = game().TILE_W * config.PLAY_LEFT_FRAC
	local gap = sidebar.sidebar_gap()
	local sidebar_x = sidebar.sidebar_right_x() - sidebar.sidebar_width()
	return {
		x = pad_x,
		w = math.max(4, sidebar_x - pad_x - gap),
	}
end

function M.hand_felt_rect()
	if game().STAGE == game().STAGES.RUN or game().STATE == game().STATES.TABLE_BOARD then
		local col = M.hand_play_column()
		local y = hud.hud_top() + hud.hud_height() + game().TILE_H * config.FELT_GAP_FRAC
		local bottom = game().TILE_H * config.BOTTOM_PAD_FRAC
		return {
			x = col.x,
			y = y,
			w = col.w,
			h = math.max(3, game().TILE_H - y - bottom),
		}
	end
	return M.felt_rect()
end

function M.play_column()
	local pad_x = game().TILE_W * config.PLAY_LEFT_FRAC
	if sidebar.is_boss_sequence() then
		local room_x = (game().ROOM and game().ROOM.T and game().ROOM.T.x) or 0
		local win_w = sidebar.window_width_tiles() - room_x
		local margin = math.max(pad_x, game().TILE_W * 0.03)
		return {
			x = margin,
			w = math.max(4, win_w - 2 * margin),
		}
	end
	local gap = sidebar.sidebar_gap()
	local sidebar_x = sidebar.sidebar_right_x() - sidebar.sidebar_width()
	return {
		x = pad_x,
		w = math.max(4, sidebar_x - pad_x - gap),
	}
end

function M.felt_rect()
	if game().STAGE == game().STAGES.RUN or game().STATE == game().STATES.TABLE_BOARD then
		local col = M.play_column()
		local y = hud.hud_top() + hud.hud_height() + game().TILE_H * config.FELT_GAP_FRAC
		local bottom = game().TILE_H * config.BOTTOM_PAD_FRAC
		return {
			x = col.x,
			y = y,
			w = col.w,
			h = math.max(3, game().TILE_H - y - bottom),
		}
	end
	return {
		x = 0.8,
		y = 2.0,
		w = game().TILE_W - 1.6,
		h = game().TILE_H - 3.5,
	}
end

function M.panel_rect()
	local felt = M.felt_rect()
	local sidebar_w = sidebar.sidebar_width()
	return {
		x = sidebar.sidebar_right_x() - sidebar_w,
		y = felt.y,
		w = sidebar_w,
		h = felt.h,
	}
end

function M.hud_offset()
	local col = M.play_column()
	return {
		x = col.x + col.w * 0.5 - game().TILE_W * 0.5,
		y = hud.hud_top(),
	}
end

return M
