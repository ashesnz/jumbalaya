--[[ devtools/sections/run.lua - Run progression cheats. ]]

local layout = require "devtools.layout"
local state = require "word_game.model.run.state"

local function tutorial_force_label()
	if WORD_GAME and WORD_GAME_UI.FirstPlayTutorial then
		return WORD_GAME_UI.FirstPlayTutorial.force_status_label()
	end
	return "OFF"
end

return {
	id = "run",
	order = 30,

	register = function(panel)
		panel.state.tutorial_force_status = tutorial_force_label()
		panel:action("delete_save", function(ctx)
			delete_saved_run()
			if ctx.game and ctx.game.discard_run then ctx.game:discard_run() end
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
		panel:action("toggle_first_play_tutorial", function()
			if WORD_GAME and WORD_GAME_UI.FirstPlayTutorial then
				WORD_GAME_UI.FirstPlayTutorial.toggle_force()
				panel:set_label("tutorial_force_status", tutorial_force_label())
			end
		end)
		panel:action("reset_first_play_tutorial", function()
			if WORD_GAME and WORD_GAME_UI.FirstPlayTutorial then
				WORD_GAME_UI.FirstPlayTutorial.reset()
				panel:set_label("tutorial_force_status", tutorial_force_label())
			end
		end)
	end,

	build = function(panel)
		local rows = {
			layout.labeled_row("tutorial_force_status", panel.state, 0.28),
		}
		for _, row in ipairs(layout.button_columns({
			{label = "Delete Save", action = "delete_save"},
			{label = "+10 Tokens", action = "add_tokens"},
			{label = "Background", action = "toggle_background"},
			{label = "Lose Run", action = "lose_game"},
			{label = "Tutorial Force", action = "toggle_first_play_tutorial"},
			{label = "Reset Tutorial", action = "reset_first_play_tutorial"},
		})) do
			rows[#rows + 1] = row
		end
		return layout.section("Run", rows)
	end,
}
