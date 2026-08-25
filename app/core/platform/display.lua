--[[
	app/core/platform/display.lua - display enumeration, boot/perf timers,
	and viewport fitting.

	Display enumeration feeds the settings menu; it refreshes the stored
	G.SETTINGS.WINDOW.DISPLAYS records and returns which resolution option is
	currently active. Viewport math keeps the room centred when the window
	resizes.
]]

-- Upper bound on retained trend samples per checkpoint.
local TREND_WINDOW = 400

--- Rebuilds the resolution option list for every connected display under the
--- given screenmode ('Windowed', 'Fullscreen', or 'Borderless').
---@return number index of the currently active entry in that list
function enumerate_display_modes(screenmode, display)
	display = display or G.SETTINGS.WINDOW.selcted_display or 1
	screenmode = screenmode or G.SETTINGS.WINDOW.screenmode or 'Windowed'

	local mode_w, mode_h = love.window.getMode()
	local current = {w = mode_w, h = mode_h}
	local active_index = 1

	G.SETTINGS.WINDOW.display_names = {}

	for i = 1, love.window.getDisplayCount() do
		local record = {}
		-- Desktop vs render dimensions work around a Windows OpenGL quirk
		-- where the DPI scaling factor comes back wrong.
		local desktop_w, desktop_h = love.window.getDesktopDimensions(i)
		record.MONITOR_DIMS = love.window.getFullscreenModes(i)[1]
		record.DPI_scale = 1 --math.floor((0.5*unscaled.w/desktop_w + 0.5*unscaled.h/desktop_h)*500 + 0.5)/500
		record.screen_resolutions = {strings = {}, values = {}}
		G.SETTINGS.WINDOW.DISPLAYS[i] = record
		G.SETTINGS.WINDOW.display_names[i] = tostring(i)

		if screenmode == 'Fullscreen' then
			active_index = collect_fullscreen_options(record, current, i, display)
		elseif screenmode == 'Windowed' then
			record.screen_resolutions.strings[1] = '-'
			record.screen_resolutions.values[1] = {w = 1280, h = 720}
		else -- Borderless: a single entry pinned to the monitor's own size
			local dims = record.MONITOR_DIMS
			record.screen_resolutions.strings[1] =
				tostring(dims.width / record.DPI_scale) .. ' X ' .. tostring(dims.height / record.DPI_scale)
			record.screen_resolutions.values[1] = current
		end
	end

	return active_index
end

--- Lists every fullscreen mode that fits this monitor, scaled by its DPI
--- factor. Flags the entry matching the live window size when we are looking
--- at both the current and selected display.
---@return number index of the matching entry, 1 if unmatched
function collect_fullscreen_options(record, current, display_index, wanted_display)
	local dims = record.MONITOR_DIMS
	for _, mode in ipairs(love.window.getFullscreenModes(display_index)) do
		local w, h = mode.width * record.DPI_scale, mode.height * record.DPI_scale
		if w <= dims.width and h <= dims.height then
			local options = record.screen_resolutions
			options.strings[#options.strings + 1] = tostring(mode.width) .. ' X ' .. tostring(mode.height)
			options.values[#options.values + 1] = {w = mode.width, h = mode.height}
			if display_index == G.SETTINGS.WINDOW.selected_display
				and display_index == wanted_display
				and current.w == mode.width and current.h == mode.height then
				return #options.values
			end
		end
	end
	return 1
end

-- Perf overlay bookkeeping, keyed by stream ('update' or 'draw').
local checkpoints

--- Records a named checkpoint on a perf stream and updates its rolling trend.
--- With `label` nil the stream resets; nothing happens unless the perf overlay
--- is enabled.
function perf_checkpoint(label, stream, reset)
	if not G.F_ENABLE_PERF_OVERLAY then return end

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
	table.insert(sample.states, 1, G.STATE)
	sample.trend[TREND_WINDOW + 1] = nil
	sample.states[TREND_WINDOW + 1] = nil

	local total = 0
	for _, value in ipairs(sample.trend) do total = total + value end
	sample.average = total / #sample.trend

	cp.samples[cp.count] = sample
	cp.last_time = now
end

--- Advances the boot loading screen to the next stage label.
function boot_stage(label, next_label, progress)
	G.LOADING = G.LOADING or {}
	G.LOADING.label = label
	G.LOADING.next = next_label
	G.LOADING.progress = progress or 0

	-- Never call love.graphics.present() here. Boot runs inside love.load(), and
	-- presenting before the main loop breaks the iOS/Metal swap chain — the last
	-- boot frames ("shared sprites" / "prep stage") can appear to loop while the
	-- game keeps updating underneath.
	G.ARGS = G.ARGS or {}
	G.ARGS.bt = love.timer and love.timer.getTime and love.timer.getTime() or 0
end

--- Refits the room transform after a resize so the board stays centred and
--- keeps its aspect ratio, then notifies the layout subsystems.
function refit_viewport(w, h)
	if not G.ROOM then return end

	local narrower_than_original = w / h < G.window_prev.orig_ratio
	if narrower_than_original then
		G.TILESCALE = G.window_prev.orig_scale * w / G.window_prev.w
	else
		G.TILESCALE = G.window_prev.orig_scale * h / G.window_prev.h
	end

	G.ROOM.T.w = G.TILE_W
	G.ROOM.T.h = G.TILE_H
	G.ROOM_ATTACH.T.w = G.TILE_W
	G.ROOM_ATTACH.T.h = G.TILE_H

	if narrower_than_original then
		G.ROOM.T.x = G.ROOM_PADDING_W
		G.ROOM.T.y = (h / (G.TILESIZE * G.TILESCALE) - (G.ROOM.T.h + G.ROOM_PADDING_H)) / 2 + G.ROOM_PADDING_H / 2
	else
		G.ROOM.T.y = G.ROOM_PADDING_H
		G.ROOM.T.x = (w / (G.TILESIZE * G.TILESCALE) - (G.ROOM.T.w + G.ROOM_PADDING_W)) / 2 + G.ROOM_PADDING_W / 2
	end

	G.ROOM_ORIG = {x = G.ROOM.T.x, y = G.ROOM.T.y, r = G.ROOM.T.r}

	update_table_board_panel_attach()
	apply_run_layout()
	if G.STAGE == G.STAGES.RUN and G.FUNCS and G.FUNCS.rebuild_table_board_sidebar then
		G.FUNCS.rebuild_table_board_sidebar()
	end
end
