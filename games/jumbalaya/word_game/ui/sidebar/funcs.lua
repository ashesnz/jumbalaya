--[[ word_game/ui/sidebar/funcs.lua - Sidebar runtime().FUNCS registration (logic on Sidebar module) ]]

local GameRT = require("word_game.ui.util.game_runtime")
local function runtime() return GameRT.game() end

local SidebarController = require("word_game.ui.controllers.sidebar")
local Funcs = require("app.callbacks.funcs")

return function(sidebar)
	local bindings = SidebarController.bind(sidebar)
	Funcs.register("ensure_table_board_sidebar", bindings.ensure_table_board_sidebar)
	Funcs.register("rebuild_table_board_sidebar", bindings.rebuild_table_board_sidebar)
	Funcs.register("end_run_from_sidebar", bindings.end_run_from_sidebar)
	Funcs.register("classic_stage_next", bindings.classic_stage_next)
end
