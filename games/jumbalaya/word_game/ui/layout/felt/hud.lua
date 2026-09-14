--[[ word_game/ui/layout/felt/hud.lua - HUD band height metrics ]]

local game = require("word_game.ui.util.game_runtime").game
local config = require("word_game.ui.layout.felt.config")

local M = {}


function M.hud_top()
	return game().TILE_H * config.HUD_TOP_FRAC
end

function M.portrait_h()
	return math.max(1.7, game().TILE_H * config.PORTRAIT_H_FRAC)
end

function M.togo_h()
	return math.max(0.8, game().TILE_H * config.TOGO_H_FRAC)
end

function M.meta_h()
	return 0
end

function M.hud_height()
	return M.portrait_h() + M.togo_h() + M.meta_h()
end

function M.portrait_name_h()
	return math.max(0.32, M.portrait_h() * 0.18)
end

return M
