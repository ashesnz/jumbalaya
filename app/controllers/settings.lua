--[[ app/controllers/settings.lua - Phase 4 window / graphics settings controller ]]

local Components = require "word_game.ui.widgets.components"
local Overlays = require("app.controllers.overlays")

local BridgeRuntime = require("bridge.runtime")
local function g() return BridgeRuntime.game() end

local M = {}

function M.change_vsync(args)
	g().SETTINGS.QUEUED_CHANGE.vsync = (g().SETTINGS.WINDOW.vsync == 0 and args.to_key == 1 and 1) or (g().SETTINGS.WINDOW.vsync == 1 and args.to_key == 2 and 0) or nil
end

function M.change_screen_resolution(args)
	local curr_disp = g().SETTINGS.WINDOW.selected_display
	local to_resolution = g().SETTINGS.WINDOW.DISPLAYS[curr_disp].screen_resolutions.values[args.to_key]
	g().SETTINGS.QUEUED_CHANGE.screenres = { w = to_resolution.w, h = to_resolution.h }
end

function M.change_screenmode(args)
	g().ARGS.screenmode_vals = g().ARGS.screenmode_vals or { "Windowed", "Fullscreen", "Borderless" }
	g().SETTINGS.QUEUED_CHANGE.screenmode = g().ARGS.screenmode_vals[args.to_key]
	M.change_window_cycle_UI()
end

function M.change_display(args)
	g().SETTINGS.QUEUED_CHANGE.selected_display = args.to_key
	M.change_window_cycle_UI()
end

function M.change_window_cycle_UI()
	if g().OVERLAY_MENU then
		local swap_node = g().OVERLAY_MENU:find_node_by_id('resolution_cycle')
		if swap_node then
			local focused_display = g().SETTINGS.QUEUED_CHANGE.selected_display or g().SETTINGS.WINDOW.selected_display
			local focused_screenmode = g().SETTINGS.QUEUED_CHANGE.screenmode or g().SETTINGS.WINDOW.screenmode
			local res_option = enumerate_display_modes(focused_screenmode, focused_display)
			swap_node.children[1]:remove()
			swap_node.children[1] = nil
			swap_node.panel:add_child(
				Components.cycler({
					width = 4, scale = 0.8,
					options = g().SETTINGS.WINDOW.DISPLAYS[focused_display].screen_resolutions.strings,
					onChange = 'change_screen_resolution',
					current_option = res_option or 1,
				}),
				swap_node)
		end
	end
end

function M.change_gamespeed(args)
	g().SETTINGS.GAMESPEED = args.to_val
end

function M.change_shadows(args)
	g().SETTINGS.GRAPHICS.shadows = args.to_key == 1 and 'On' or 'Off'
	g():queue_settings_write()
end

function M.change_pixel_smoothing(args)
	g().SETTINGS.GRAPHICS.texture_scaling = args.to_key
	g():set_render_settings()
	g():queue_settings_write()
end

function M.can_apply_window_changes(e)
	local can_apply = false
	if g().SETTINGS.QUEUED_CHANGE then
		if g().SETTINGS.QUEUED_CHANGE.screenmode
			and g().SETTINGS.QUEUED_CHANGE.screenmode ~= g().SETTINGS.WINDOW.screenmode then
			can_apply = true
		elseif g().SETTINGS.QUEUED_CHANGE.screenres then
			can_apply = true
		elseif g().SETTINGS.QUEUED_CHANGE.vsync then
			can_apply = true
		elseif g().SETTINGS.QUEUED_CHANGE.selected_display
			and g().SETTINGS.QUEUED_CHANGE.selected_display ~= g().SETTINGS.WINDOW.selected_display then
			can_apply = true
		end
	end

	if can_apply then
		e.config.button = 'apply_window_changes'
		e.config.colour = g().C.RED
	else
		e.config.button = nil
		e.config.colour = g().C.UI.BACKGROUND_INACTIVE
	end
end

function M.apply_window_changes(_initial)
	g().SETTINGS.WINDOW.screenmode = (g().SETTINGS.QUEUED_CHANGE and g().SETTINGS.QUEUED_CHANGE.screenmode) or g().SETTINGS.WINDOW.screenmode or 'Windowed'
	g().SETTINGS.WINDOW.selected_display = (g().SETTINGS.QUEUED_CHANGE and g().SETTINGS.QUEUED_CHANGE.selected_display) or g().SETTINGS.WINDOW.selected_display or 1

	enumerate_display_modes(g().SETTINGS.WINDOW.screenmode, g().SETTINGS.WINDOW.selected_display)
	local display_count = love.window.getDisplayCount()
	if g().SETTINGS.WINDOW.selected_display > display_count then
		g().SETTINGS.WINDOW.selected_display = display_count
	end
	if g().SETTINGS.WINDOW.selected_display < 1 then
		g().SETTINGS.WINDOW.selected_display = 1
	end

	g().SETTINGS.WINDOW.DISPLAYS[g().SETTINGS.WINDOW.selected_display].screen_res = {
		w = (g().SETTINGS.QUEUED_CHANGE and g().SETTINGS.QUEUED_CHANGE.screenres and g().SETTINGS.QUEUED_CHANGE.screenres.w) or (g().SETTINGS.screen_res and g().SETTINGS.screen_res.w) or love.graphics.getWidth(),
		h = (g().SETTINGS.QUEUED_CHANGE and g().SETTINGS.QUEUED_CHANGE.screenres and g().SETTINGS.QUEUED_CHANGE.screenres.h) or (g().SETTINGS.screen_res and g().SETTINGS.screen_res.h) or love.graphics.getHeight()
	}

	g().SETTINGS.WINDOW.vsync = (g().SETTINGS.QUEUED_CHANGE and g().SETTINGS.QUEUED_CHANGE.vsync) or g().SETTINGS.WINDOW.vsync or 1

	love.window.updateMode(
		(g().SETTINGS.QUEUED_CHANGE and g().SETTINGS.QUEUED_CHANGE.screenmode == 'Windowed') and love.graphics.getWidth() * 0.8 or g().SETTINGS.WINDOW.DISPLAYS[g().SETTINGS.WINDOW.selected_display].screen_res.w,
		(g().SETTINGS.QUEUED_CHANGE and g().SETTINGS.QUEUED_CHANGE.screenmode == 'Windowed') and love.graphics.getHeight() * 0.8 or g().SETTINGS.WINDOW.DISPLAYS[g().SETTINGS.WINDOW.selected_display].screen_res.h,
		{
			fullscreen = g().SETTINGS.WINDOW.screenmode ~= 'Windowed',
			fullscreentype = (g().SETTINGS.WINDOW.screenmode == 'Borderless' and 'desktop') or (g().SETTINGS.WINDOW.screenmode == 'Fullscreen' and 'exclusive') or nil,
			vsync = g().SETTINGS.WINDOW.vsync,
			resizable = true,
			display = g().SETTINGS.WINDOW.selected_display
		})
	g().SETTINGS.QUEUED_CHANGE = {}
	if _initial ~= true then
		love.resize(love.graphics.getWidth(), love.graphics.getHeight())
		g():queue_settings_write()
	end
	if g().OVERLAY_MENU then
		local tab_but = g().OVERLAY_MENU:find_node_by_id('tab_but_Video')
		Overlays.switch_tab(tab_but)
	end
end

return M
