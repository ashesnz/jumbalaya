--[[ jumbalaya-engine/persistence/save_queue.lua - flushes pending write flags to disk ]]

local shell = require("jumbalaya-engine.shell")
local Tables = require("jumbalaya-engine.util.tables")

local M = {}

function M.update()
	local game = shell.game()
	if not game then return end

	local flags = game.WRITE_FLAGS
	if not flags or not flags.update_queued then return end

	local flush_aux = flags.settings or flags.progress or flags.metrics
	local flush_run = flags.run and (
		flags.force
		or flags.last_sent_stage ~= game.STAGE
		or ((flags.last_sent_pause ~= game.SETTINGS.paused) and flags.run)
		or (not flags.last_sent_time or (flags.last_sent_time < (game.TIMERS.UPTIME - 30)))
	)
	if not flush_aux and not flush_run then
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
		local payload = game.ARGS.settings_payload or game.SETTINGS
		local profile_num = game.SETTINGS.profile or 1
		local snapshot = Tables.save_safe_clone(payload)
		local profile_snapshot = Tables.save_safe_clone(game.PROFILES[profile_num] or {})
		if channel then
			channel:push({
				op = 'settings',
				settings = snapshot,
				profile_num = profile_num,
				profile = profile_snapshot,
			})
		else
			local pack = require("jumbalaya-engine.util.pack")
			pack.write_game_save('settings', snapshot)
			pack.write_game_save(profile_num .. '/profile', profile_snapshot)
		end
	end

	if flags.run and flush_run then
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

--- Forces any queued settings/progress/metrics (and run when eligible) to disk.
function M.flush_now()
	local game = shell.game()
	if not game then return end
	game.WRITE_FLAGS = game.WRITE_FLAGS or {}
	game.WRITE_FLAGS.force = true
	game.WRITE_FLAGS.update_queued = true
	if game.SETTINGS and game.queue_settings_write then
		game:queue_settings_write()
	end
	M.update()
end

return M
