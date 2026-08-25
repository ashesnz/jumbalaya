--[[ word_game/ui/sidebar/callbacks.lua - Sidebar G.FUNCS install (instance-bound) ]]

local hud_definition = require("word_game.ui.sidebar.hud_definition")
local register_sidebar = require("word_game.ui.callbacks.sidebar")

local M = {}

function M.install(self)
	register_sidebar(self, hud_definition)
end

return M
