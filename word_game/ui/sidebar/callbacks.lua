--[[ word_game/ui/sidebar/callbacks.lua - Sidebar G.FUNCS install (instance-bound) ]]

local register_sidebar = require("word_game.ui.sidebar.funcs")

local M = {}

function M.install(self)
	register_sidebar(self)
end

return M
