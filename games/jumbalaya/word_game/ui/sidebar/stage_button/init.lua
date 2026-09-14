--[[ word_game/ui/sidebar/stage_button/init.lua - End Run / Next sidebar button facade ]]

local state = require("word_game.ui.sidebar.stage_button.state")
local layout = require("word_game.ui.sidebar.stage_button.layout")
local animate = require("word_game.ui.sidebar.stage_button.animate")
local input = require("word_game.ui.sidebar.stage_button.input")

local M = {}

function M.label_scale_for(text)
	return layout.label_scale_for(text)
end

function M.bind_button_proxy(button, label)
	state.bind_proxy(button, label)
	if not button then
		M.reset()
	end
end

function M.current_label()
	return state.current_label()
end

function M.current_action()
	return state.current_action()
end

function M.current_colour()
	return state.current_colour() or layout.red_colour()
end

function M.is_next_mode()
	return animate.is_next_mode()
end

function M.reset()
	state.reset_fields()
	local w = state.widget()
	w.panel_colour = layout.red_colour()
	local col = layout.button_column()
	if col and col.config then
		layout.set_display_mode(col, "end_run")
		layout.set_button_rotation(col, 0)
	end
end

function M.sync()
	animate.sync()
end

function M.update(dt)
	local result = animate.update(dt)
	if result == "reset" then
		M.reset()
	elseif result == "reset_and_sync" then
		M.reset()
		M.sync()
	end
end

function M.point_in_button(rect, tx, ty)
	return input.point_in_button(rect, tx, ty)
end

function M.consume_click(mx, my, rect)
	return input.consume_click(mx, my, rect)
end

function M.draw(rect)
	layout.draw(rect)
end

function M.collect_and_advance()
	return input.collect_and_advance()
end

function M.press()
	return input.press()
end

return M
