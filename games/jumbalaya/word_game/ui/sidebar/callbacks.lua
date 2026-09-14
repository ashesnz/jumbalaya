--[[ word_game/ui/sidebar/callbacks.lua - Sidebar game().FUNCS install (instance-bound) ]]

local game = require("word_game.ui.util.game_runtime").game

local register_sidebar = require("word_game.ui.sidebar.funcs")

local M = {}

function M.install(self)
	register_sidebar(self)
end

return M
