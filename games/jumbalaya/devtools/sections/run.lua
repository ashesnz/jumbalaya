--[[ devtools/sections/run.lua - Run progression cheats. ]]

local layout = require "devtools.layout"

local function run_state()
	return WORD_GAME and WORD_GAME.Run and WORD_GAME.Run.State
end

local function grant_debug_tokens(amount)
	local state = run_state()
	if not state or state.add_tokens(amount) <= 0 then
		return
	end
	if WORD_GAME_UI and WORD_GAME_UI.TradeUI and WORD_GAME_UI.TradeUI.refresh_after_tokens_changed then
		WORD_GAME_UI.TradeUI.refresh_after_tokens_changed()
	end
end

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
		panel:action("add_tokens_100", function(ctx)
			if ctx:is_run_stage() then grant_debug_tokens(100) end
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
			{label = "+100 Tokens", action = "add_tokens_100"},
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
