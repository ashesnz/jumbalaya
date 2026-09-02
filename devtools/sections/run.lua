--[[ devtools/sections/run.lua - Run progression cheats. ]]

local layout = require "devtools.layout"
local state = require "word_game.model.state"

return {
	id = "run",
	order = 30,

	register = function(panel)
		panel:action("delete_save", function()
			delete_saved_run()
			if G and G.discard_run then G:discard_run() end
		end)
		panel:action("add_tokens", function(ctx)
			if ctx:is_run_stage() then state.add_tokens(10) end
		end)
		panel:action("toggle_background", function(ctx)
			ctx.game.debug_background_toggle = not ctx.game.debug_background_toggle
		end)
		panel:action("lose_game", function(ctx)
			if ctx:is_run_stage() then
				ctx.game.STATE = ctx.game.STATES.GAME_OVER
				ctx.game.STATE_COMPLETE = false
			end
		end)
	end,

	build = function(_panel)
		return layout.section("Run", layout.button_columns({
			{label = "Delete Save", action = "delete_save"},
			{label = "+10 Tokens", action = "add_tokens"},
			{label = "Background", action = "toggle_background"},
			{label = "Lose Run", action = "lose_game"},
		}))
	end,
}
