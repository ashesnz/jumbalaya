--[[ app/controllers/settings.lua - Phase 4 window / graphics settings controller ]]

local Components = require "word_game.ui.widgets.components"
local Overlays = require("app.controllers.overlays")

local M = {}

function M.change_vsync(args)
	G.SETTINGS.QUEUED_CHANGE.vsync = (G.SETTINGS.WINDOW.vsync == 0 and args.to_key == 1 and 1) or (G.SETTINGS.WINDOW.vsync == 1 and args.to_key == 2 and 0) or nil
end

function M.change_screen_resolution(args)
	local curr_disp = G.SETTINGS.WINDOW.selected_display
	local to_resolution = G.SETTINGS.WINDOW.DISPLAYS[curr_disp].screen_resolutions.values[args.to_key]
	G.SETTINGS.QUEUED_CHANGE.screenres = { w = to_resolution.w, h = to_resolution.h }
end

function M.change_screenmode(args)
	G.ARGS.screenmode_vals = G.ARGS.screenmode_vals or { "Windowed", "Fullscreen", "Borderless" }
	G.SETTINGS.QUEUED_CHANGE.screenmode = G.ARGS.screenmode_vals[args.to_key]
	M.change_window_cycle_UI()
end

function M.change_display(args)
	G.SETTINGS.QUEUED_CHANGE.selected_display = args.to_key
	M.change_window_cycle_UI()
end

function M.change_window_cycle_UI()
	if G.OVERLAY_MENU then
		local swap_node = G.OVERLAY_MENU:find_node_by_id('resolution_cycle')
		if swap_node then
			local focused_display = G.SETTINGS.QUEUED_CHANGE.selected_display or G.SETTINGS.WINDOW.selected_display
			local focused_screenmode = G.SETTINGS.QUEUED_CHANGE.screenmode or G.SETTINGS.WINDOW.screenmode
			local res_option = enumerate_display_modes(focused_screenmode, focused_display)
			swap_node.children[1]:remove()
			swap_node.children[1] = nil
			swap_node.LayoutView:add_child(
				Components.cycler({
					width = 4, scale = 0.8,
					options = G.SETTINGS.WINDOW.DISPLAYS[focused_display].screen_resolutions.strings,
					onChange = 'change_screen_resolution',
					current_option = res_option or 1,
				}),
				swap_node)
		end
	end
end

function M.change_gamespeed(args)
	G.SETTINGS.GAMESPEED = args.to_val
end

function M.change_shadows(args)
	G.SETTINGS.GRAPHICS.shadows = args.to_key == 1 and 'On' or 'Off'
	G:queue_settings_write()
end

function M.change_pixel_smoothing(args)
	G.SETTINGS.GRAPHICS.texture_scaling = args.to_key
	G:set_render_settings()
	G:queue_settings_write()
end

function M.can_apply_window_changes(e)
	local can_apply = false
	if G.SETTINGS.QUEUED_CHANGE then
		if G.SETTINGS.QUEUED_CHANGE.screenmode
			and G.SETTINGS.QUEUED_CHANGE.screenmode ~= G.SETTINGS.WINDOW.screenmode then
			can_apply = true
		elseif G.SETTINGS.QUEUED_CHANGE.screenres then
			can_apply = true
		elseif G.SETTINGS.QUEUED_CHANGE.vsync then
			can_apply = true
		elseif G.SETTINGS.QUEUED_CHANGE.selected_display
			and G.SETTINGS.QUEUED_CHANGE.selected_display ~= G.SETTINGS.WINDOW.selected_display then
			can_apply = true
		end
	end

	if can_apply then
		e.config.button = 'apply_window_changes'
		e.config.colour = G.C.RED
	else
		e.config.button = nil
		e.config.colour = G.C.UI.BACKGROUND_INACTIVE
	end
end

function M.apply_window_changes(_initial)
	G.SETTINGS.WINDOW.screenmode = (G.SETTINGS.QUEUED_CHANGE and G.SETTINGS.QUEUED_CHANGE.screenmode) or G.SETTINGS.WINDOW.screenmode or 'Windowed'
	G.SETTINGS.WINDOW.selected_display = (G.SETTINGS.QUEUED_CHANGE and G.SETTINGS.QUEUED_CHANGE.selected_display) or G.SETTINGS.WINDOW.selected_display or 1

	enumerate_display_modes(G.SETTINGS.WINDOW.screenmode, G.SETTINGS.WINDOW.selected_display)
	local display_count = love.window.getDisplayCount()
	if G.SETTINGS.WINDOW.selected_display > display_count then
		G.SETTINGS.WINDOW.selected_display = display_count
	end
	if G.SETTINGS.WINDOW.selected_display < 1 then
		G.SETTINGS.WINDOW.selected_display = 1
	end

	G.SETTINGS.WINDOW.DISPLAYS[G.SETTINGS.WINDOW.selected_display].screen_res = {
		w = (G.SETTINGS.QUEUED_CHANGE and G.SETTINGS.QUEUED_CHANGE.screenres and G.SETTINGS.QUEUED_CHANGE.screenres.w) or (G.SETTINGS.screen_res and G.SETTINGS.screen_res.w) or love.graphics.getWidth(),
		h = (G.SETTINGS.QUEUED_CHANGE and G.SETTINGS.QUEUED_CHANGE.screenres and G.SETTINGS.QUEUED_CHANGE.screenres.h) or (G.SETTINGS.screen_res and G.SETTINGS.screen_res.h) or love.graphics.getHeight()
	}

	G.SETTINGS.WINDOW.vsync = (G.SETTINGS.QUEUED_CHANGE and G.SETTINGS.QUEUED_CHANGE.vsync) or G.SETTINGS.WINDOW.vsync or 1

	love.window.updateMode(
		(G.SETTINGS.QUEUED_CHANGE and G.SETTINGS.QUEUED_CHANGE.screenmode == 'Windowed') and love.graphics.getWidth() * 0.8 or G.SETTINGS.WINDOW.DISPLAYS[G.SETTINGS.WINDOW.selected_display].screen_res.w,
		(G.SETTINGS.QUEUED_CHANGE and G.SETTINGS.QUEUED_CHANGE.screenmode == 'Windowed') and love.graphics.getHeight() * 0.8 or G.SETTINGS.WINDOW.DISPLAYS[G.SETTINGS.WINDOW.selected_display].screen_res.h,
		{
			fullscreen = G.SETTINGS.WINDOW.screenmode ~= 'Windowed',
			fullscreentype = (G.SETTINGS.WINDOW.screenmode == 'Borderless' and 'desktop') or (G.SETTINGS.WINDOW.screenmode == 'Fullscreen' and 'exclusive') or nil,
			vsync = G.SETTINGS.WINDOW.vsync,
			resizable = true,
			display = G.SETTINGS.WINDOW.selected_display
		})
	G.SETTINGS.QUEUED_CHANGE = {}
	if _initial ~= true then
		love.resize(love.graphics.getWidth(), love.graphics.getHeight())
		G:queue_settings_write()
	end
	if G.OVERLAY_MENU then
		local tab_but = G.OVERLAY_MENU:find_node_by_id('tab_but_Video')
		Overlays.switch_tab(tab_but)
	end
end

return M
