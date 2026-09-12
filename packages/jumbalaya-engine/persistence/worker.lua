--[[
	jumbalaya-engine/persistence/worker.lua - disk write thread logic.

	Thread entry: app/persistence/worker.lua (love.thread loads from game source).
]]

local M = {}

function M.run()
	local inbound = love.thread.getChannel("disk_write_queue")

	local function merge_badges(meta, badges)
		local changed = false
		for key, flags in pairs(badges) do
			if string.find(flags, 'u') and not meta.unlocked[key] then
				meta.unlocked[key] = true
				changed = true
			end
			if string.find(flags, 'd') and not meta.discovered[key] then
				meta.discovered[key] = true
				changed = true
			end
			if string.find(flags, 'a') and not meta.alerted[key] then
				meta.alerted[key] = true
				changed = true
			end
		end
		return changed
	end

	local function profile_dir(profile_num)
		local prefix = (profile_num or 1) .. ''
		if not love.filesystem.getInfo(prefix) then
			love.filesystem.createDirectory(prefix)
		end
		return prefix .. '/'
	end

	local HANDLERS = {}

	function HANDLERS.progress(request)
		local payload = request.progress
		local prefix = profile_dir(payload.SETTINGS.profile)

		if not love.filesystem.getInfo(prefix..'meta.acs') then
			love.filesystem.append(prefix..'meta.acs', 'return {}')
		end

		local meta = unpack_source(read_save_payload(prefix..'meta.acs') or 'return {}')
		meta.unlocked = meta.unlocked or {}
		meta.discovered = meta.discovered or {}
		meta.alerted = meta.alerted or {}

		if merge_badges(meta, payload.UDA) then
			write_save_file(prefix..'meta.acs', pack_to_source(meta))
		end

		write_save_file('settings.acs', payload.SETTINGS)
		write_save_file(prefix..'profile.acs', payload.PROFILE)

		inbound:push('done')
	end

	function HANDLERS.settings(request)
		write_save_file('settings.acs', request.settings)
		write_save_file((request.profile_num or 1)..'/profile.acs', request.profile)
	end

	function HANDLERS.metrics(request)
		write_save_file('metrics.acs', request.metrics)
	end

	function HANDLERS.run(request)
		local prefix = profile_dir(request.profile_num)
		write_save_file(prefix..'save.acs', request.snapshot)
	end

	function HANDLERS.purge(request)
		love.filesystem.remove((request.profile_num or 1)..'/save.acs')
	end

	while true do
		local request = inbound:demand()
		if request then
			local handler = HANDLERS[request.op]
			if handler then handler(request) end
		end
	end
end

return M
