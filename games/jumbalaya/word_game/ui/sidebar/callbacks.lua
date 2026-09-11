--[[ word_game/ui/sidebar/callbacks.lua - Sidebar runtime().FUNCS install (instance-bound) ]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local register_sidebar = require("word_game.ui.sidebar.funcs")

local M = {}

function M.install(self)
	register_sidebar(self)
end

return M
