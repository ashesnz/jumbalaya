local shell = require("jumbalaya-engine.shell")
local function g() return shell.game() end

--[[ jumbalaya-engine/adapters/love2d/window.lua - Window callbacks, mobile landscape lock, viewport ]]

local Window = {}

local LANDSCAPE_W, LANDSCAPE_H = 1280, 720

function Window.is_mobile_os()
	local os_name = love.system and love.system.getOS and love.system.getOS() or ""
	return os_name == "iOS" or os_name == "Android"
end

function Window.landscape_dimensions(w, h)
	w, h = w or 0, h or 0
	if h > w then
		w, h = h, w
	end
	return w, h
end

function Window.get_backbuffer_dimensions()
	if love.graphics and love.graphics.getDimensions then
		return love.graphics.getDimensions()
	end
	if love.graphics and love.graphics.getWidth and love.graphics.getHeight then
		return love.graphics.getWidth(), love.graphics.getHeight()
	end
	if love.window and love.window.getMode then
		return love.window.getMode()
	end
	return 0, 0
end

function Window.get_render_dimensions()
	local w, h = Window.get_backbuffer_dimensions()
	if Window.is_mobile_os() then
		w, h = Window.landscape_dimensions(w, h)
	end
	return w, h
end

function Window.is_portrait_window()
	local w, h = Window.get_backbuffer_dimensions()
	return h > w
end

function Window.lock_landscape_orientation()
	if not Window.is_mobile_os() or not love.window or not love.window.setMode then
		return false
	end

	local vsync = 1
	if g() and g().SETTINGS and g().SETTINGS.WINDOW and g().SETTINGS.WINDOW.vsync ~= nil then
		vsync = g().SETTINGS.WINDOW.vsync
	end

	love.window.setMode(LANDSCAPE_W, LANDSCAPE_H, {
		resizable = false,
		highdpi = true,
		vsync = vsync,
		fullscreen = false,
	})

	return true
end

function Window.apply_mobile_window()
	if not Window.lock_landscape_orientation() then
		return nil, nil
	end

	if g() and g().ROOM_PADDING_W then
		return Window.sync_resize()
	end
	return LANDSCAPE_W, LANDSCAPE_H
end

function Window.sync_resize()
	if Window.is_mobile_os() and Window.is_portrait_window() then
		Window.lock_landscape_orientation()
	end

	local w, h = Window.get_render_dimensions()
	if w <= 0 or h <= 0 or not love.resize then
		return nil, nil
	end
	love.resize(w, h)
	return w, h
end

function love.resize(width, height)
	if Window.is_mobile_os() then
		if height > width then
			Window.lock_landscape_orientation()
			width, height = Window.landscape_dimensions(width, height)
		end
	end

	local tile_w = g().TILE_W or 20
	local tile_h = g().TILE_H or 11.5
	local pad_w = g().ROOM_PADDING_W or 1
	local pad_h = g().ROOM_PADDING_H or 0.7

	g().WINDOW_TRANSFORM = {
		x = 0,
		y = 0,
		w = tile_w + 2 * pad_w,
		h = tile_h + 2 * pad_h,
		real_window_w = width,
		real_window_h = height,
	}
	g().CANVAS_SCALE = 1

	local os_name = love.system and love.system.getOS and love.system.getOS() or ""
	local canvas_opts = (os_name == "iOS" or os_name == "Android") and { type = "2d" }
		or { type = "2d", readable = true }

	g().CANVAS = love.graphics.newCanvas(
		width * g().CANVAS_SCALE,
		height * g().CANVAS_SCALE,
		canvas_opts
	)
	g().CANVAS:setFilter("linear", "linear")

	if not g().ROOM then
		return
	end

	refit_viewport(width, height)
	if g().buttons then
		g().buttons:recalculate()
	end
	if g().STAGE == g().STAGES.RUN and g().STATE == g().STATES.TABLE_BOARD then
		if apply_run_layout then
			apply_run_layout()
		end
	elseif g().STAGE == g().STAGES.MAIN_MENU and layout_main_menu then
		layout_main_menu()
	end
end

function love.displayrotated(_index, orientation)
	if not Window.is_mobile_os() then
		return
	end
	if orientation == "portrait" or orientation == "portraitflipped" then
		Window.lock_landscape_orientation()
		if g() and g().ROOM_PADDING_W then
			Window.sync_resize()
		end
	end
end

return Window
