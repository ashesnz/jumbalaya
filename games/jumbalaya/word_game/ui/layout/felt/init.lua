--[[ word_game/ui/layout/felt/init.lua - Play column, felt, panel, and HUD metrics ]]

local config = require("word_game.ui.layout.felt.config")
local sidebar = require("word_game.ui.layout.felt.sidebar")
local hud = require("word_game.ui.layout.felt.hud")
local rects = require("word_game.ui.layout.felt.rects")
local metrics = require("word_game.ui.layout.felt.metrics")

local M = {}

for k, v in pairs(config) do
	M[k] = v
end

M.sidebar_frac = sidebar.sidebar_frac
M.sidebar_width = sidebar.sidebar_width
M.sidebar_gap = sidebar.sidebar_gap
M.right_margin = sidebar.right_margin
M.window_width_tiles = sidebar.window_width_tiles
M.is_boss_sequence = sidebar.is_boss_sequence
M.sidebar_right_x = sidebar.sidebar_right_x

M.hud_top = hud.hud_top
M.portrait_h = hud.portrait_h
M.togo_h = hud.togo_h
M.meta_h = hud.meta_h
M.hud_height = hud.hud_height
M.portrait_name_h = hud.portrait_name_h

M.hand_play_column = rects.hand_play_column
M.hand_felt_rect = rects.hand_felt_rect
M.play_column = rects.play_column
M.felt_rect = rects.felt_rect
M.panel_rect = rects.panel_rect
M.hud_offset = rects.hud_offset

M.metrics = metrics.metrics
M.inner_width = metrics.inner_width

return M
