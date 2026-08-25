--[[ app/core/session/loop/save_queue.lua - flushes pending write flags to disk ]]

local M = {}

--- Called once per frame from Game:update. When writes are pending and the
--- throttle allows (stage change, pause flip, force flag, or 30s heartbeat),
--- pushes each flagged payload to the disk worker and clears the flags.
function M.update()
	local flags = G.WRITE_FLAGS
	if not flags or not flags.update_queued then return end
	if not (
		flags.force or
		flags.last_sent_stage ~= G.STAGE or
		((flags.last_sent_pause ~= G.SETTINGS.paused) and flags.run) or
		(not flags.last_sent_time or (flags.last_sent_time < (G.TIMERS.UPTIME - 30)))
	) then
		return
	end

	local channel = G.DISK_WORKER and G.DISK_WORKER.channel

	if flags.metrics then
		if G.F_VERBOSE then print('SAVING METRICS') end
		if channel then
			channel:push({ op = 'metrics', metrics = G.ARGS.metrics_payload })
		end
	end

	if flags.progress then
		if G.F_VERBOSE then print('SAVING PROGRESS') end
		if channel then
			channel:push({ op = 'progress', progress = G.ARGS.progress_payload })
		end
	elseif flags.settings then
		if G.F_VERBOSE then print('SAVING SETTINGS') end
		if channel then
			channel:push({
				op = 'settings',
				settings = G.ARGS.settings_payload,
				profile_num = G.SETTINGS.profile,
				profile = G.PROFILES[G.SETTINGS.profile],
			})
		end
	end

	if flags.run then
		if G.F_VERBOSE then print('SAVING RUN') end
		if channel then
			channel:push({
				op = 'run',
				snapshot = G.ARGS.run_snapshot,
				profile_num = G.SETTINGS.profile,
			})
		end
		G.STORED_RUN = nil
	end

	flags.force = false
	flags.last_sent_stage = G.STAGE
	flags.last_sent_time = G.TIMERS.UPTIME
	flags.last_sent_pause = G.SETTINGS.paused
	flags.settings = nil
	flags.progress = nil
	flags.metrics = nil
	flags.run = nil
end

return M
