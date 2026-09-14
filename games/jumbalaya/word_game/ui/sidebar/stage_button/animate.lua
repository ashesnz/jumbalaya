--[[ word_game/ui/sidebar/stage_button/animate.lua - Classic End Run → Next transition ]]

local facade = require("word_game.ui.facade")
local table_discard = require("word_game.ui.perks.discard_bin")
local state = require("word_game.ui.sidebar.stage_button.state")
local layout = require("word_game.ui.sidebar.stage_button.layout")

local M = {}

local TRANSITION_DUR = 0.55

local function run_mode()
	return facade.run_mode()
end

local function widget()
	return state.widget()
end

local function clamp01(t)
	if t < 0 then return 0 end
	if t > 1 then return 1 end
	return t
end

local function ease_out_cubic(t)
	t = clamp01(t)
	local inv = 1 - t
	return 1 - inv * inv * inv
end

local function lerp_colour(a, b, t)
	return {
		a[1] + (b[1] - a[1]) * t,
		a[2] + (b[2] - a[2]) * t,
		a[3] + (b[3] - a[3]) * t,
		(a[4] or 1) + ((b[4] or 1) - (a[4] or 1)) * t,
	}
end

function M.is_next_mode()
	if not table_discard.end_run_button_visible() then return false end
	if not run_mode().is_classic() then return false end
	local tt = WORD_GAME_UI.TimelineTimer
	if not tt or not tt.is_progress_mode or not tt.is_progress_mode() then return false end
	if tt.sync_progress then tt.sync_progress() end
	return tt.goal_reached == true
end

function M.sync()
	local w = widget()
	w.visible = table_discard.end_run_button_visible()
	local col = layout.button_column()
	if col and col.config then
		if col.states then col.states.visible = w.visible end
		col.config.visible = w.visible
	end
	if not w.visible then return end

	if w.mode == "next" and not w.transitioning then
		layout.set_display_mode(col, "next")
		layout.set_button_rotation(col, 0)
	elseif not w.transitioning then
		layout.set_display_mode(col, "end_run")
		layout.set_button_rotation(col, 0)
	end
	layout.apply_widget_to_proxy()
end

function M.update(dt)
	dt = dt or 0
	local w = widget()
	if not table_discard.end_run_button_visible() then
		if w.mode ~= "end_run" or w.transitioning then
			return "reset"
		end
		return
	end

	local next_mode = M.is_next_mode()
	local col = layout.button_column()

	if next_mode ~= w.known_next_mode then
		w.known_next_mode = next_mode
		if WORD_GAME_UI.TableControls and WORD_GAME_UI.TableControls.sync_visibility then
			WORD_GAME_UI.TableControls.sync_visibility()
		end
	end

	if next_mode and w.mode == "end_run" and not w.transitioning then
		w.transitioning = true
		w.transition_t = 0
	elseif not next_mode and (w.mode == "next" or w.transitioning) then
		return "reset_and_sync"
	end

	if w.transitioning and col then
		w.transition_t = w.transition_t + dt
		local u = ease_out_cubic(w.transition_t / TRANSITION_DUR)
		layout.set_button_rotation(col, u * math.pi * 2)

		if u < 0.42 then
			layout.set_display_mode(col, "end_run", { panel_colour = layout.red_colour() })
		else
			local morph = (u - 0.42) / 0.58
			layout.set_display_mode(col, "next", {
				panel_colour = lerp_colour(layout.red_colour(), layout.blue_colour(), morph),
				label_text = state.LABEL_NEXT,
			})
		end

		if w.transition_t >= TRANSITION_DUR then
			w.transitioning = false
			w.mode = "next"
			layout.set_display_mode(col, "next")
			layout.set_button_rotation(col, 0)
		end
	elseif w.mode == "next" and col then
		layout.set_display_mode(col, "next")
	end
	layout.apply_widget_to_proxy()
end

return M
