--[[ jumbalaya-engine/persistence/save_queue.lua - flushes pending write flags to disk ]]

local shell = require("jumbalaya-engine.shell")

local M = {}

function M.update()
	local game = shell.game()
	if not game then return end

	local flags = game.WRITE_FLAGS
	if not flags or not flags.update_queued then return end
	if not (
		flags.force or
		flags.last_sent_stage ~= game.STAGE or
		((flags.last_sent_pause ~= game.SETTINGS.paused) and flags.run) or
		(not flags.last_sent_time or (flags.last_sent_time < (game.TIMERS.UPTIME - 30)))
	) then
		return
	end

	local channel = game.DISK_WORKER and game.DISK_WORKER.channel

	if flags.metrics then
		if game.F_VERBOSE then print('SAVING METRICS') end
		if channel then
			channel:push({ op = 'metrics', metrics = game.ARGS.metrics_payload })
		end
	end

	if flags.progress then
		if game.F_VERBOSE then print('SAVING PROGRESS') end
		if channel then
			channel:push({ op = 'progress', progress = game.ARGS.progress_payload })
		end
	elseif flags.settings then
		if game.F_VERBOSE then print('SAVING SETTINGS') end
		if channel then
			channel:push({
				op = 'settings',
				settings = game.ARGS.settings_payload,
				profile_num = game.SETTINGS.profile,
				profile = game.PROFILES[game.SETTINGS.profile],
			})
		end
	end

	if flags.run then
		if game.F_VERBOSE then print('SAVING RUN') end
		if channel then
			channel:push({
				op = 'run',
				snapshot = game.ARGS.run_snapshot,
				profile_num = game.SETTINGS.profile,
			})
		end
		game.STORED_RUN = nil
	end

	flags.force = false
	flags.last_sent_stage = game.STAGE
	flags.last_sent_time = game.TIMERS.UPTIME
	flags.last_sent_pause = game.SETTINGS.paused
	flags.settings = nil
	flags.progress = nil
	flags.metrics = nil
	flags.run = nil
end

return M
