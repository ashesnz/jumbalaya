--[[
	jumbalaya-engine/persistence/worker.lua - disk write thread logic.

	Thread entry: app/persistence/worker.lua (love.thread loads from game source).
]]

local pack = require("jumbalaya-engine.util.pack")
local SavePaths = require("jumbalaya-engine.persistence.save_paths")

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

	local function ensure_meta_stub(profile_num)
		local rel = (profile_num or 1) .. "/meta"
		if not love.filesystem.getInfo(SavePaths.read_path_for(rel)) then
			love.filesystem.append(SavePaths.write_path_for(rel), 'return {}')
		end
	end

	local HANDLERS = {}

	function HANDLERS.progress(request)
		local payload = request.progress
		local profile_num = payload.SETTINGS.profile
		ensure_meta_stub(profile_num)

		local meta = pack.unpack_source(pack.read_game_save(profile_num .. "/meta") or 'return {}')
		meta.unlocked = meta.unlocked or {}
		meta.discovered = meta.discovered or {}
		meta.alerted = meta.alerted or {}

		if merge_badges(meta, payload.UDA) then
			pack.write_game_save(profile_num .. "/meta", pack.pack_to_source(meta))
		end

		pack.write_game_save('settings', payload.SETTINGS)
		pack.write_game_save(profile_num .. '/profile', payload.PROFILE)

		inbound:push('done')
	end

	function HANDLERS.settings(request)
		local profile_num = request.profile_num or 1
		pack.write_game_save('settings', request.settings)
		pack.write_game_save(profile_num .. '/profile', request.profile)
	end

	function HANDLERS.metrics(request)
		pack.write_game_save('metrics', request.metrics)
	end

	function HANDLERS.run(request)
		local profile_num = request.profile_num or 1
		pack.write_game_save(profile_num .. '/save', request.snapshot)
	end

	function HANDLERS.purge(request)
		local profile_num = request.profile_num or 1
		love.filesystem.remove(SavePaths.write_path_for(profile_num .. '/save'))
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
