--[[ word_game/ui/sidebar/stage_button/state.lua - End Run / Next widget state ]]

local M = {}

M.LABEL_END_RUN = "End Run"
M.LABEL_NEXT = "Next"

local widget = {
	mode = "end_run",
	transitioning = false,
	transition_t = 0,
	known_next_mode = false,
	visible = true,
	panel_colour = nil,
	label_text = M.LABEL_END_RUN,
	button_action = "end_run_from_sidebar",
	rotation = 0,
}

local bound_button
local bound_label

function M.widget()
	return widget
end

function M.bind_proxy(button, label)
	bound_button = button
	bound_label = label
end

function M.bound_button()
	return bound_button
end

function M.bound_label()
	return bound_label
end

function M.current_label()
	return widget.label_text
end

function M.current_action()
	return widget.button_action
end

function M.current_colour()
	return widget.panel_colour
end

function M.reset_fields()
	widget.mode = "end_run"
	widget.transitioning = false
	widget.transition_t = 0
	widget.known_next_mode = false
	widget.rotation = 0
	widget.visible = true
	widget.panel_colour = nil
	widget.label_text = M.LABEL_END_RUN
	widget.button_action = "end_run_from_sidebar"
end

return M
