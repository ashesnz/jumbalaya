--[[ word_game/ui/layout/felt/sidebar.lua - Sidebar column metrics ]]

local facade = require("word_game.ui.facade")
local game_access = facade.game_access()
local GameRT = require("word_game.ui.util.game_runtime")
local config = require("word_game.ui.layout.felt.config")

local M = {}

local function runtime()
	return GameRT.game()
end

function M.sidebar_width()
	return runtime().TABLE_BOARD_SIDEBAR_WIDTH or config.SIDEBAR_WIDTH
end

function M.sidebar_frac()
	return M.sidebar_width() / (runtime().TILE_W or 20)
end

function M.sidebar_gap()
	return math.max(0.15, runtime().TILE_W * 0.01)
end

function M.right_margin()
	return 0
end

function M.window_width_tiles()
	local ts = (runtime().TILESIZE or 1) * (runtime().TILESCALE or 1)
	if love and love.graphics and love.graphics.getWidth then
		return love.graphics.getWidth() / ts
	end
	return runtime().TILE_W or 20
end

function M.sidebar_right_x()
	local room_x = (runtime().ROOM and runtime().ROOM.T and runtime().ROOM.T.x) or 0
	return M.window_width_tiles() - room_x
end

function M.is_boss_sequence()
	local wr = game_access.word_round()
	local j = wr and wr.jumble
	if not j then return false end
	return j.boss_word_active or j.boss_word_staging or j.boss_puzzle_hidden
end

return M
