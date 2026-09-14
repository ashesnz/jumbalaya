--[[ word_game/ui/menu/animate/init.lua - Title garden pan and main menu open lifecycle ]]

local garden = require("word_game.ui.menu.animate.garden")
local open = require("word_game.ui.menu.animate.open")

local M = {}

M.title_garden_sprite_dims = garden.title_garden_sprite_dims
M.title_garden_pan_offset = garden.title_garden_pan_offset
M.update_title_garden_pan = garden.update_title_garden_pan
M.open_main_menu = open.open_main_menu

return M
