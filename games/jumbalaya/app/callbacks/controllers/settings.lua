--[[ app/controllers/settings.lua - Phase 4 window / graphics settings controller ]]

local Components = require "word_game.ui.widgets.components"
local Overlays = require("app.callbacks.controllers.overlays")

local game = require("app.runtime").game

local M = {}

local enumerate_display_modes = require("jumbalaya-engine.adapters.love2d.display").enumerate_display_modes
function M.change_vsync(args)
	game().SETTINGS.QUEUED_CHANGE.vsync = (game().SETTINGS.WINDOW.vsync == 0 and args.to_key == 1 and 1) or (game().SETTINGS.WINDOW.vsync == 1 and args.to_key == 2 and 0) or nil
end

function M.change_screen_resolution(args)
	local curr_disp = game().SETTINGS.WINDOW.selected_display
	local to_resolution = game().SETTINGS.WINDOW.DISPLAYS[curr_disp].screen_resolutions.values[args.to_key]
	game().SETTINGS.QUEUED_CHANGE.screenres = { w = to_resolution.w, h = to_resolution.h }
end

function M.change_screenmode(args)
	game().ARGS.screenmode_vals = game().ARGS.screenmode_vals or { "Windowed", "Fullscreen", "Borderless" }
	game().SETTINGS.QUEUED_CHANGE.screenmode = game().ARGS.screenmode_vals[args.to_key]
	M.change_window_cycle_UI()
end

function M.change_display(args)
	game().SETTINGS.QUEUED_CHANGE.selected_display = args.to_key
	M.change_window_cycle_UI()
end

function M.change_window_cycle_UI()
	if game().OVERLAY_MENU then
		local swap_node = game().OVERLAY_MENU:find_node_by_id('resolution_cycle')
		if swap_node then
			local focused_display = game().SETTINGS.QUEUED_CHANGE.selected_display or game().SETTINGS.WINDOW.selected_display
			local focused_screenmode = game().SETTINGS.QUEUED_CHANGE.screenmode or game().SETTINGS.WINDOW.screenmode
			local res_option = enumerate_display_modes(focused_screenmode, focused_display)
			swap_node.children[1]:remove()
			swap_node.children[1] = nil
			swap_node.panel:add_child(
				Components.cycler({
					width = 4, scale = 0.8,
					options = game().SETTINGS.WINDOW.DISPLAYS[focused_display].screen_resolutions.strings,
					onChange = 'change_screen_resolution',
					current_option = res_option or 1,
				}),
				swap_node)
		end
	end
end

function M.change_gamespeed(args)
	game().SETTINGS.GAMESPEED = args.to_val
end

function M.change_shadows(args)
	game().SETTINGS.GRAPHICS.shadows = args.to_key == 1 and 'On' or 'Off'
	game():queue_settings_write()
end

function M.change_pixel_smoothing(args)
	game().SETTINGS.GRAPHICS.texture_scaling = args.to_key
	game():set_render_settings()
	game():queue_settings_write()
end

function M.can_apply_window_changes(e)
	local can_apply = false
	if game().SETTINGS.QUEUED_CHANGE then
		if game().SETTINGS.QUEUED_CHANGE.screenmode
			and game().SETTINGS.QUEUED_CHANGE.screenmode ~= game().SETTINGS.WINDOW.screenmode then
			can_apply = true
		elseif game().SETTINGS.QUEUED_CHANGE.screenres then
			can_apply = true
		elseif game().SETTINGS.QUEUED_CHANGE.vsync then
			can_apply = true
		elseif game().SETTINGS.QUEUED_CHANGE.selected_display
			and game().SETTINGS.QUEUED_CHANGE.selected_display ~= game().SETTINGS.WINDOW.selected_display then
			can_apply = true
		end
	end

	if can_apply then
		e.config.button = 'apply_window_changes'
		e.config.colour = game().C.RED
	else
		e.config.button = nil
		e.config.colour = game().C.UI.BACKGROUND_INACTIVE
	end
end

function M.apply_window_changes(_initial)
	game().SETTINGS.WINDOW.screenmode = (game().SETTINGS.QUEUED_CHANGE and game().SETTINGS.QUEUED_CHANGE.screenmode) or game().SETTINGS.WINDOW.screenmode or 'Windowed'
	game().SETTINGS.WINDOW.selected_display = (game().SETTINGS.QUEUED_CHANGE and game().SETTINGS.QUEUED_CHANGE.selected_display) or game().SETTINGS.WINDOW.selected_display or 1

	enumerate_display_modes(game().SETTINGS.WINDOW.screenmode, game().SETTINGS.WINDOW.selected_display)
	local display_count = love.window.getDisplayCount()
	if game().SETTINGS.WINDOW.selected_display > display_count then
		game().SETTINGS.WINDOW.selected_display = display_count
	end
	if game().SETTINGS.WINDOW.selected_display < 1 then
		game().SETTINGS.WINDOW.selected_display = 1
	end

	game().SETTINGS.WINDOW.DISPLAYS[game().SETTINGS.WINDOW.selected_display].screen_res = {
		w = (game().SETTINGS.QUEUED_CHANGE and game().SETTINGS.QUEUED_CHANGE.screenres and game().SETTINGS.QUEUED_CHANGE.screenres.w) or (game().SETTINGS.screen_res and game().SETTINGS.screen_res.w) or love.graphics.getWidth(),
		h = (game().SETTINGS.QUEUED_CHANGE and game().SETTINGS.QUEUED_CHANGE.screenres and game().SETTINGS.QUEUED_CHANGE.screenres.h) or (game().SETTINGS.screen_res and game().SETTINGS.screen_res.h) or love.graphics.getHeight()
	}

	game().SETTINGS.WINDOW.vsync = (game().SETTINGS.QUEUED_CHANGE and game().SETTINGS.QUEUED_CHANGE.vsync) or game().SETTINGS.WINDOW.vsync or 1

	love.window.updateMode(
		(game().SETTINGS.QUEUED_CHANGE and game().SETTINGS.QUEUED_CHANGE.screenmode == 'Windowed') and love.graphics.getWidth() * 0.8 or game().SETTINGS.WINDOW.DISPLAYS[game().SETTINGS.WINDOW.selected_display].screen_res.w,
		(game().SETTINGS.QUEUED_CHANGE and game().SETTINGS.QUEUED_CHANGE.screenmode == 'Windowed') and love.graphics.getHeight() * 0.8 or game().SETTINGS.WINDOW.DISPLAYS[game().SETTINGS.WINDOW.selected_display].screen_res.h,
		{
			fullscreen = game().SETTINGS.WINDOW.screenmode ~= 'Windowed',
			fullscreentype = (game().SETTINGS.WINDOW.screenmode == 'Borderless' and 'desktop') or (game().SETTINGS.WINDOW.screenmode == 'Fullscreen' and 'exclusive') or nil,
			vsync = game().SETTINGS.WINDOW.vsync,
			resizable = true,
			display = game().SETTINGS.WINDOW.selected_display
		})
	game().SETTINGS.QUEUED_CHANGE = {}
	if _initial ~= true then
		love.resize(love.graphics.getWidth(), love.graphics.getHeight())
		game():queue_settings_write()
	end
	if game().OVERLAY_MENU then
		local tab_but = game().OVERLAY_MENU:find_node_by_id('tab_but_Video')
		Overlays.switch_tab(tab_but)
	end
end

return M
