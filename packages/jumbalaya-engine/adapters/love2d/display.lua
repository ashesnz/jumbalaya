local shell = require("jumbalaya-engine.shell")
local function g() return shell.game() end

--[[
	jumbalaya-engine/adapters/love2d/display.lua - display enumeration, boot/perf timers,
	and viewport fitting.

	Display enumeration feeds the settings menu; it refreshes the stored
	g().SETTINGS.WINDOW.DISPLAYS records and returns which resolution option is
	currently active. Viewport math keeps the room centred when the window
	resizes.
]]

local TREND_WINDOW = 400
local checkpoints

function enumerate_display_modes(screenmode, display)
	display = display or g().SETTINGS.WINDOW.selcted_display or 1
	screenmode = screenmode or g().SETTINGS.WINDOW.screenmode or 'Windowed'

	local mode_w, mode_h = love.window.getMode()
	local current = {w = mode_w, h = mode_h}
	local active_index = 1

	g().SETTINGS.WINDOW.display_names = {}

	for i = 1, love.window.getDisplayCount() do
		local record = {}
		local desktop_w, desktop_h = love.window.getDesktopDimensions(i)
		record.MONITOR_DIMS = love.window.getFullscreenModes(i)[1]
		record.DPI_scale = 1
		record.screen_resolutions = {strings = {}, values = {}}
		g().SETTINGS.WINDOW.DISPLAYS[i] = record
		g().SETTINGS.WINDOW.display_names[i] = tostring(i)

		if screenmode == 'Fullscreen' then
			active_index = collect_fullscreen_options(record, current, i, display)
		elseif screenmode == 'Windowed' then
			record.screen_resolutions.strings[1] = '-'
			record.screen_resolutions.values[1] = {w = 1280, h = 720}
		else
			local dims = record.MONITOR_DIMS
			record.screen_resolutions.strings[1] =
				tostring(dims.width / record.DPI_scale) .. ' X ' .. tostring(dims.height / record.DPI_scale)
			record.screen_resolutions.values[1] = current
		end
	end

	return active_index
end

function collect_fullscreen_options(record, current, display_index, wanted_display)
	local dims = record.MONITOR_DIMS
	for _, mode in ipairs(love.window.getFullscreenModes(display_index)) do
		local w, h = mode.width * record.DPI_scale, mode.height * record.DPI_scale
		if w <= dims.width and h <= dims.height then
			local options = record.screen_resolutions
			options.strings[#options.strings + 1] = tostring(mode.width) .. ' X ' .. tostring(mode.height)
			options.values[#options.values + 1] = {w = mode.width, h = mode.height}
			if display_index == g().SETTINGS.WINDOW.selected_display
				and display_index == wanted_display
				and current.w == mode.width and current.h == mode.height then
				return #options.values
			end
		end
	end
	return 1
end

function perf_checkpoint(label, stream, reset)
	if not g().F_ENABLE_PERF_OVERLAY then return end

	checkpoints = checkpoints or {
		draw = {samples = {}, count = 0, last_time = 0},
		update = {samples = {}, count = 0, last_time = 0},
	}

	local cp = checkpoints[stream]
	local now = love.timer.getTime()

	if not label or reset then
		cp.last_time = now
		cp.count = 0
		return
	end

	cp.count = cp.count + 1
	local sample = cp.samples[cp.count] or {trend = {}, states = {}}
	sample.label = label
	sample.time = now
	sample.TTC = now - cp.last_time
	table.insert(sample.trend, 1, sample.TTC)
	table.insert(sample.states, 1, g().STATE)
	sample.trend[TREND_WINDOW + 1] = nil
	sample.states[TREND_WINDOW + 1] = nil

	local total = 0
	for _, value in ipairs(sample.trend) do total = total + value end
	sample.average = total / #sample.trend

	cp.samples[cp.count] = sample
	cp.last_time = now
end

function boot_stage(label, next_label, progress)
	g().LOADING = g().LOADING or {}
	g().LOADING.label = label
	g().LOADING.next = next_label
	g().LOADING.progress = progress or 0

	g().ARGS = g().ARGS or {}
	g().ARGS.bt = love.timer and love.timer.getTime and love.timer.getTime() or 0
end

function refit_viewport(w, h)
	if not g().ROOM then return end

	local narrower_than_original = w / h < g().window_prev.orig_ratio
	if narrower_than_original then
		g().TILESCALE = g().window_prev.orig_scale * w / g().window_prev.w
	else
		g().TILESCALE = g().window_prev.orig_scale * h / g().window_prev.h
	end

	g().ROOM.T.w = g().TILE_W
	g().ROOM.T.h = g().TILE_H
	g().ROOM_ATTACH.T.w = g().TILE_W
	g().ROOM_ATTACH.T.h = g().TILE_H

	if narrower_than_original then
		g().ROOM.T.x = g().ROOM_PADDING_W
		g().ROOM.T.y = (h / (g().TILESIZE * g().TILESCALE) - (g().ROOM.T.h + g().ROOM_PADDING_H)) / 2 + g().ROOM_PADDING_H / 2
	else
		g().ROOM.T.y = g().ROOM_PADDING_H
		g().ROOM.T.x = (w / (g().TILESIZE * g().TILESCALE) - (g().ROOM.T.w + g().ROOM_PADDING_W)) / 2 + g().ROOM_PADDING_W / 2
	end

	g().ROOM_ORIG = {x = g().ROOM.T.x, y = g().ROOM.T.y, r = g().ROOM.T.r}

	if update_table_board_panel_attach then
		update_table_board_panel_attach()
	end
	if apply_run_layout then
		apply_run_layout()
	end
	if g().notify_display_changed then
		g().notify_display_changed()
	end
end
