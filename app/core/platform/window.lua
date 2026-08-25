-- Window callbacks, mobile landscape lock, and viewport reconstruction.

local Window = {}

-- Fixed landscape size passed to setMode. Width MUST exceed height so LÖVE/SDL
-- request landscape on iOS (see love.window.setMode wiki).
local LANDSCAPE_W, LANDSCAPE_H = 1280, 720

---@return boolean
function Window.is_mobile_os()
	local os_name = love.system and love.system.getOS and love.system.getOS() or ""
	return os_name == "iOS" or os_name == "Android"
end

--- Force landscape aspect: width is always the long edge.
---@param w number
---@param h number
---@return number, number
function Window.landscape_dimensions(w, h)
	w, h = w or 0, h or 0
	if h > w then
		w, h = h, w
	end
	return w, h
end

--- Window size in the same coordinate space LÖVE uses for drawing.
---@return number, number
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

---@return number, number
function Window.get_render_dimensions()
	local w, h = Window.get_backbuffer_dimensions()
	if Window.is_mobile_os() then
		w, h = Window.landscape_dimensions(w, h)
	end
	return w, h
end

---@return boolean
function Window.is_portrait_window()
	local w, h = Window.get_backbuffer_dimensions()
	return h > w
end

--- Ask the OS for landscape using a fixed width>height mode.
--- Do NOT pass the current (possibly portrait) window size here — that does not
--- rotate the device, it only reshapes the drawable incorrectly.
---@return boolean
function Window.lock_landscape_orientation()
	if not Window.is_mobile_os() or not love.window or not love.window.setMode then
		return false
	end

	local vsync = 1
	if G and G.SETTINGS and G.SETTINGS.WINDOW and G.SETTINGS.WINDOW.vsync ~= nil then
		vsync = G.SETTINGS.WINDOW.vsync
	end

	love.window.setMode(LANDSCAPE_W, LANDSCAPE_H, {
		resizable = false,
		highdpi = true,
		vsync = vsync,
		fullscreen = false,
	})

	return true
end

--- Force landscape via setMode, then rebuild canvas when layout constants exist.
---@return number|nil, number|nil
function Window.apply_mobile_window()
	if not Window.lock_landscape_orientation() then
		return nil, nil
	end

	if G and G.ROOM_PADDING_W then
		return Window.sync_resize()
	end
	return LANDSCAPE_W, LANDSCAPE_H
end

--- Rebuild canvas + viewport from the current window size.
---@return number|nil, number|nil
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

---@param width number
---@param height number
function love.resize(width, height)
	if Window.is_mobile_os() then
		if height > width then
			Window.lock_landscape_orientation()
			width, height = Window.landscape_dimensions(width, height)
		end
	end

	local tile_w = G.TILE_W or 20
	local tile_h = G.TILE_H or 11.5
	local pad_w = G.ROOM_PADDING_W or 1
	local pad_h = G.ROOM_PADDING_H or 0.7

	G.WINDOW_TRANSFORM = {
		x = 0,
		y = 0,
		w = tile_w + 2 * pad_w,
		h = tile_h + 2 * pad_h,
		real_window_w = width,
		real_window_h = height,
	}
	G.CANVAS_SCALE = 1

	local os_name = love.system and love.system.getOS and love.system.getOS() or ""
	local canvas_opts = (os_name == "iOS" or os_name == "Android") and { type = "2d" }
		or { type = "2d", readable = true }

	G.CANVAS = love.graphics.newCanvas(
		width * G.CANVAS_SCALE,
		height * G.CANVAS_SCALE,
		canvas_opts
	)
	G.CANVAS:setFilter("linear", "linear")

	if not G.ROOM then
		return
	end

	refit_viewport(width, height)
	if G.buttons then
		G.buttons:recalculate()
	end
	if G.STAGE == G.STAGES.RUN and G.hand then
		apply_run_layout()
	end
end

--- Reject portrait orientation on mobile; Jumbalaya is landscape-only.
---@param _index number
---@param orientation string
function love.displayrotated(_index, orientation)
	if not Window.is_mobile_os() then
		return
	end
	if orientation == "portrait" or orientation == "portraitflipped" then
		Window.lock_landscape_orientation()
		if G and G.ROOM_PADDING_W then
			Window.sync_resize()
		end
	end
end

return Window
